//
//  RoomSessionManager.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation
import CryptoKit
import Combine

/// Manager za WebSocket komunikaciju s relay serverom
final class RoomSessionManager: ObservableObject {
    
    // PUBLIC state za UI
    @Published var messages: [Message] = []
    @Published var isSessionReady: Bool = false
    @Published var lastError: String? = nil
    @Published var networkLogs: [String] = [] // Logovi za mrežne događaje
    
    // WS
    private var urlSession: URLSession = URLSession(configuration: .default)
    private var webSocketTask: URLSessionWebSocketTask?
    
    // join state
    var roomCode: String?
    private var pendingJoinCompletion: ((Bool, String?) -> Void)?
    
    // reference na masterKey i serverAddress
    private var masterKey: SymmetricKey?
    private var serverAddress: String = "https://amessagesserver.onrender.com"
    
    // Callback za sistemske poruke (za agent integraciju)
    var systemMessageHandler: ((String) -> Void)?
    
    // E2E transport root key (za poruke preko mreže)
    private var transportRootKey: SymmetricKey?
    private var sendCounter: UInt64 = 0   // index za naše poslane poruke
    
    deinit {
        close()
    }
    
    // MARK: - JOIN
    
    /// Spoji se na sobu (join) i čekaj `session_ready`.
    func joinRoom(
        code: String,
        masterKey: SymmetricKey?,
        serverAddress: String? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("🧵 [ROOM] joinRoom(\(code)) – start")
        
        guard code.count == 16 else {
            completion(false, "Kod mora imati 16 znakova.")
            return
        }
        
        self.masterKey = masterKey
        self.serverAddress = serverAddress ?? "https://amessagesserver.onrender.com"
        pendingJoinCompletion = completion
        lastError = nil
        isSessionReady = false
        roomCode = code
        
        transportRootKey = nil
        sendCounter = 0
        
        // Inicijaliziraj E2E transport root ključ (ako imamo masterKey)
        if let mk = masterKey {
            let salt = Data("TreeOfChoice-Transport-\(code)".utf8)
            let info = Data("TreeOfChoice-Transport-Root".utf8)
            let root = HKDF<SHA256>.deriveKey(
                inputKeyMaterial: mk,
                salt: salt,
                info: info,
                outputByteCount: 32
            )
            transportRootKey = root
            print("🔐 [ROOM] transportRootKey inicijaliziran.")
        } else {
            print("⚠️ [ROOM] Nema masterKey-a – poruke će ići u čistom tekstu.")
        }
        
        guard let wsURL = makeWebSocketURL(from: self.serverAddress) else {
            print("🧵 [ROOM] Neispravan serverAddress: \(self.serverAddress)")
            completion(false, "Neispravna adresa servera.")
            return
        }
        
        print("🧵 [ROOM] Spajam se na WS: \(wsURL.absoluteString)")
        addNetworkLog("WebSocket URL: \(wsURL.absoluteString)")
        addNetworkLog("Connecting to WebSocket: \(wsURL.absoluteString)")
        
        webSocketTask = urlSession.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        
        // start receive loop
        listenForMessages()
        
        // pošalji JOIN
        let joinPayload: [String: Any] = [
            "t": "join",
            "code": code,
            "mode": "direct"
        ]
        
        sendJSON(joinPayload) { [weak self] error in
            if let error = error {
                print("🧵 [ROOM] JOIN send error:", error)
                self?.addNetworkLog("Failed to send JOIN: \(error.localizedDescription)")
                self?.finishJoin(success: false, errorText: "Ne mogu poslati join: \(error.localizedDescription)")
            } else {
                print("🧵 [ROOM] JOIN frame poslan.")
                self?.addNetworkLog("JOIN message sent to server")
            }
        }
    }
    
    // MARK: - Slanje tekst poruke (E2E)
    
    func sendText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let code = roomCode else {
            print("🧵 [ROOM] sendText: nema roomCode-a")
            return
        }
        
        print("💬 [ROOM] sendText -> '\(trimmed)'")
        
        var bodyToSend = trimmed
        var indexToSend: UInt64? = nil
        var encLabel: String? = nil
        
        // Ako imamo transportRootKey → E2E enkripcija
        if let root = transportRootKey {
            sendCounter += 1
            indexToSend = sendCounter
            do {
                let msgKey = try deriveTransportKey(rootKey: root, index: sendCounter)
                let encrypted = try MessageCryptoService.encryptString(trimmed, with: msgKey)
                bodyToSend = encrypted
                encLabel = "aesgcm-hkdf-v1"
                print("🔐 [ROOM] Poruka enkriptirana za index=\(sendCounter)")
            } catch {
                print("❌ [ROOM] Greška pri E2E enkripciji – šaljem plain. Error:", error)
                indexToSend = nil
                encLabel = nil
                bodyToSend = trimmed
            }
        }
        
        var payload: [String: Any] = [
            "t": "msg",
            "code": code,
            "body": bodyToSend
        ]
        
        if let idx = indexToSend {
            payload["k"] = idx        // message index
        }
        if let enc = encLabel {
            payload["enc"] = enc      // oznaka algoritma
        }
        
        sendJSON(payload) { [weak self] error in
            if let error = error {
                print("💬 [ROOM] sendText error:", error)
                self?.addNetworkLog("Failed to send message: \(error.localizedDescription)")
            } else {
                print("💬 [ROOM] sendText OK")
                self?.addNetworkLog("Message sent successfully")
            }
        }
        
        // lokalno dodaj outgoing poruku (plaintext)
        let msg = Message(
            id: UUID(),
            conversationId: code,
            direction: .outgoing,
            timestamp: Date(),
            text: trimmed
        )
        
        DispatchQueue.main.async {
            self.messages.append(msg)
        }
    }
    
    // MARK: - Ping Server
    
    /// Ping server da provjeri je li živ (koristi trenutnu serverAddress)
    func pingServer(completion: @escaping (Bool, String?) -> Void) {
        pingServerWithAddress(serverAddress, completion: completion)
    }
    
    /// Ping server s custom adresom (kao AMessages - samo provjeri format)
    func pingServerWithAddress(_ address: String, completion: @escaping (Bool, String?) -> Void) {
        let baseURL = address.isEmpty ? "https://amessagesserver.onrender.com" : address
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Jednostavna provjera formata (kao AMessages)
        if trimmed.isEmpty {
            addNetworkLog("Server address is empty")
            completion(false, "Server address is empty")
            return
        }
        
        // Provjeri format URL-a - samo format, ne stvarni request
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            addNetworkLog("URL format is valid: \(trimmed)")
            completion(true, "URL format is valid")
        } else {
            addNetworkLog("Invalid URL format - must start with http:// or https://")
            completion(false, "Invalid URL format - must start with http:// or https://")
        }
    }
    
    // MARK: - Network Logging
    
    private func addNetworkLog(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = Date()
            let logMessage = "[\(timestamp.formatted(date: .omitted, time: .standard))] \(message)"
            self.networkLogs.append(logMessage)
            
            // Zadrži samo zadnjih 200 logova
            if self.networkLogs.count > 200 {
                self.networkLogs.removeFirst()
            }
            
            print("📡 [NETWORK] \(logMessage)")
        }
    }
    
    // MARK: - Zatvaranje
    
    func close() {
        print("🧵 [ROOM] close() – zatvaram WS, čistim state.")
        pendingJoinCompletion = nil
        transportRootKey = nil
        sendCounter = 0
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - Private: URL helper
    
    private func makeWebSocketURL(from serverAddress: String) -> URL? {
        // ako nema ništa u postavkama → default
        let base = serverAddress.isEmpty
        ? "https://amessagesserver.onrender.com"
        : serverAddress

        guard let httpURL = URL(string: base) else {
            addNetworkLog("Invalid server address format: \(base)")
            return nil
        }

        var comps = URLComponents()
        comps.scheme = (httpURL.scheme == "https") ? "wss" : "ws"
        comps.host = httpURL.host
        comps.port = httpURL.port
        comps.path = httpURL.path.isEmpty ? "/" : httpURL.path

        let finalURL = comps.url
        addNetworkLog("WebSocket URL: \(finalURL?.absoluteString ?? "invalid")")
        return finalURL
    }
    
    // MARK: - Private: slanje JSON-a
    
    private func sendJSON(_ json: [String: Any],
                          completion: ((Error?) -> Void)? = nil) {
        guard let ws = webSocketTask else {
            completion?(NSError(domain: "RoomSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nema WS taska"]))
            return
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let text = String(data: data, encoding: .utf8) else {
                completion?(NSError(domain: "RoomSession", code: -2, userInfo: [NSLocalizedDescriptionKey: "Ne mogu napraviti string iz JSON-a"]))
                return
            }
            
            print("📤 [ROOM] SEND:", text)
            
            ws.send(.string(text)) { error in
                if let error = error {
                    print("📤 [ROOM] send error:", error)
                }
                completion?(error)
            }
        } catch {
            print("📤 [ROOM] JSON serialization error:", error)
            completion?(error)
        }
    }
    
    // MARK: - Receive petlja
    
    private func listenForMessages() {
        guard let ws = webSocketTask else { return }
        
        ws.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("📥 [ROOM] receive error:", error)
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                }
                // ako smo još u join fazi → fail
                if self.pendingJoinCompletion != nil {
                    self.finishJoin(success: false, errorText: error.localizedDescription)
                }
            case .success(let message):
                self.handle(message)
                // nastavi slušat
                self.listenForMessages()
            }
        }
    }
    
    private func handle(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            print("📥 [ROOM] RX string:", text)
            handleIncomingText(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                print("📥 [ROOM] RX data->string:", text)
                handleIncomingText(text)
            } else {
                print("📥 [ROOM] RX binarno, ignoriram.")
            }
        @unknown default:
            print("📥 [ROOM] RX unknown message type")
        }
    }
    
    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        let jsonObj = (try? JSONSerialization.jsonObject(with: data, options: [])) as Any
        guard let dict = jsonObj as? [String: Any] else {
            print("📥 [ROOM] Nije validan JSON.")
            return
        }
        
        guard let type = dict["t"] as? String else {
            print("📥 [ROOM] Nema 't' field-a.")
            return
        }
        
        switch type {
        case "joined":
            print("✅ [ROOM] joined confirmed")
            addNetworkLog("Joined room successfully - waiting for other party")
            // ništa posebno – čekamo session_ready
            
        case "session_ready":
            print("✅ [ROOM] session_ready – razgovor može krenuti")
            addNetworkLog("Session ready - other party connected")
            DispatchQueue.main.async {
                self.isSessionReady = true
            }
            finishJoin(success: true, errorText: nil)
            
            // sistemska poruka za UI
            if let code = roomCode {
                let msg = Message(
                    id: UUID(),
                    conversationId: code,
                    direction: .system,
                    timestamp: Date(),
                    text: "Druga strana je spojena. Možete početi razgovor."
                )
                DispatchQueue.main.async {
                    self.messages.append(msg)
                }
                
                // Obavijesti sistem message handler da se konekcija uspostavila
                if let handler = self.systemMessageHandler {
                    print("📡 [ROOM] Šaljem signal 'connection_established' agentu")
                    handler("connection_established:\(code)")
                }
            }
            
        case "msg":
            addNetworkLog("Received message from network")
            handleIncomingChat(dict: dict)
            
        case "extend_request":
            print("⏳ [ROOM] extend_request:", dict)
            
        case "extended":
            print("⏳ [ROOM] extended:", dict)
            
        case "expired":
            print("⛔️ [ROOM] expired:", dict)
            DispatchQueue.main.async {
                self.isSessionReady = false
                self.lastError = "Razgovor je istekao."
            }
            
        case "error":
            handleServerError(dict: dict)
            
        case "pong":
            print("🏓 [ROOM] pong:", dict)
            
        default:
            print("📥 [ROOM] Nepoznat 't': \(type)")
        }
    }
    
    private func handleIncomingChat(dict: [String: Any]) {
        guard
            let code = dict["code"] as? String,
            let body = dict["body"] as? String
        else {
            print("📥 [ROOM] msg: nedostaju code/body")
            return
        }
        
        let enc = dict["enc"] as? String
        let kAny = dict["k"]
        
        var plainText = body
        
        if enc == "aesgcm-hkdf-v1",
           let root = transportRootKey {
            
            var index: UInt64?
            
            if let n = kAny as? NSNumber {
                index = UInt64(truncating: n)
            } else if let i = kAny as? Int {
                index = UInt64(i)
            }
            
            if let idx = index {
                do {
                    let msgKey = try deriveTransportKey(rootKey: root, index: idx)
                    let decrypted = try MessageCryptoService.decryptString(body, with: msgKey)
                    plainText = decrypted
                    print("🔐 [ROOM] Dekriptirana poruka za index=\(idx)")
                } catch {
                    print("❌ [ROOM] Greška pri dekripciji E2E poruke:", error)
                    plainText = "[DECRYPT ERROR]"
                }
            } else {
                print("⚠️ [ROOM] enc=\(enc ?? "") ali nema valjanog 'k' – tretiram kao plain.")
            }
        } else {
            if enc != nil {
                print("⚠️ [ROOM] enc=\(enc ?? "nil") ali nema transportRootKey. Tretiram body kao plain.")
            }
        }
        
        // Provjeri je li sistemska poruka (ima prefiks "sys:")
        if plainText.hasPrefix("sys:") {
            systemMessageHandler?(plainText)
            return // Ne dodaj sistemsku poruku u normalne poruke
        }
        
        let msg = Message(
            id: UUID(),
            conversationId: code,
            direction: .incoming,
            timestamp: Date(),
            text: plainText
        )
        
        DispatchQueue.main.async {
            self.messages.append(msg)
        }
    }
    
    private func handleServerError(dict: [String: Any]) {
        let reason = dict["reason"] as? String ?? "error"
        let message = dict["message"] as? String ?? "Greška s poslužitelja."
        
        let full = "[\(reason)] \(message)"
        print("❌ [ROOM] SERVER ERROR:", full)
        
        DispatchQueue.main.async {
            self.lastError = full
        }
        
        // ako smo još u join fazi → fail join
        if pendingJoinCompletion != nil {
            finishJoin(success: false, errorText: full)
        } else if let code = roomCode {
            // sistemska poruka u razgovor (incoming)
            let msg = Message(
                id: UUID(),
                conversationId: code,
                direction: .system,
                timestamp: Date(),
                text: full
            )
            DispatchQueue.main.async {
                self.messages.append(msg)
            }
        }
    }
    
    private func finishJoin(success: Bool, errorText: String?) {
        if let cb = pendingJoinCompletion {
            DispatchQueue.main.async {
                cb(success, errorText)
            }
        }
        pendingJoinCompletion = nil
        if !success, let err = errorText {
            DispatchQueue.main.async {
                self.lastError = err
            }
        }
    }
    
    // MARK: - E2E: derivacija transport ključa po poruci
    
    private func deriveTransportKey(rootKey: SymmetricKey, index: UInt64) throws -> SymmetricKey {
        var idxBE = index.bigEndian
        let idxData = Data(bytes: &idxBE, count: MemoryLayout<UInt64>.size)
        let info = Data("TreeOfChoice-Transport-Msg".utf8) + idxData
        
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: rootKey,
            salt: Data(),
            info: info,
            outputByteCount: 32
        )
        return key
    }
}

