//
//  SettingsPage.swift
//  Alexandria
//
//  Postavke – Chrome-style full view, sidebar s kategorijama.
//

import SwiftUI

// MARK: - Kategorije postavki
enum SettingsCategory: String, CaseIterable {
    case general = "Općenito"
    case searchEngines = "Pretraga aplikacija"
    case appearance = "Izgled"
    case network = "Mreža"
    case privacy = "Privatnost"
    case security = "Sigurnost"
    case about = "O aplikaciji"
    
    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .searchEngines: return "magnifyingglass"
        case .appearance: return "paintbrush.fill"
        case .network: return "globe"
        case .privacy: return "lock.shield.fill"
        case .security: return "checkmark.shield.fill"
        case .about: return "info.circle.fill"
        }
    }
}

struct SettingsView: View {
    var onClose: () -> Void
    @State private var selectedCategory: SettingsCategory = .general
    @ObservedObject private var manager = ProfileManager.shared
    @AppStorage("searchPanelPosition") private var searchPanelPositionRaw = SearchPanelPosition.both.rawValue
    @AppStorage("isIncognito") private var isIncognito = false
    @State private var islandTitle: String = ""
    @State private var showAddProfile = false
    
    private var accentColor: Color { AlexandriaTheme.accentColor }
    
    var body: some View {
        ZStack {
            AppBackgroundView()
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentColor)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(accentColor.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    Text("Postavke")
                        .font(.title2.bold())
                        .foregroundColor(accentColor)
                }
                .padding(20)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SettingsCategory.allCases, id: \.self) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 14))
                                    .frame(width: 20, alignment: .center)
                                Text(cat.rawValue)
                                    .font(.system(size: 14, weight: selectedCategory == cat ? .semibold : .regular))
                            }
                            .foregroundColor(selectedCategory == cat ? accentColor : .white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedCategory == cat ? accentColor.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                
                Spacer()
            }
            .frame(width: 240)
            .background(Color.black.opacity(0.6))
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Sadržaj
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedCategory {
                    case .general:
                        GeneralSettingsSection(
                            islandTitle: $islandTitle,
                            searchPanelPositionRaw: $searchPanelPositionRaw,
                            showAddProfile: $showAddProfile,
                            manager: manager,
                            accentColor: accentColor
                        )
                    case .searchEngines:
                        SearchEnginesSettingsSection(accentColor: accentColor)
                    case .appearance:
                        AppearanceSettingsSection(accentColor: accentColor)
                    case .network:
                        NetworkSettingsSection(accentColor: accentColor)
                    case .privacy:
                        PrivacySettingsSection(isIncognito: $isIncognito, accentColor: accentColor)
                    case .security:
                        SecuritySettingsSection(accentColor: accentColor)
                    case .about:
                        AboutSettingsSection(accentColor: accentColor)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { islandTitle = AppSettings.islandTitle }
        .sheet(isPresented: $showAddProfile) {
            AddProfileView(onDismiss: { showAddProfile = false })
        }
    }
}

// MARK: - Općenito
private struct GeneralSettingsSection: View {
    @Binding var islandTitle: String
    @Binding var searchPanelPositionRaw: String
    @AppStorage("onOpenAction") private var onOpenActionRaw = OnOpenAction.search.rawValue
    @Binding var showAddProfile: Bool
    @ObservedObject var manager: ProfileManager
    let accentColor: Color
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Općenito")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Profili") {
                HStack {
                    Spacer()
                    SettingsPrimaryButton(title: "Dodaj profil", accentColor: accentColor) {
                        showAddProfile = true
                    }
                }
                ForEach(manager.profiles) { profile in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            if profile.id == manager.currentProfile?.id {
                                Text("Aktivan")
                                    .font(.system(size: 11))
                                    .foregroundColor(accentColor)
                            }
                        }
                        Spacer()
                        if profile.id != manager.currentProfile?.id {
                            SettingsPrimaryButton(title: "Koristi", accentColor: accentColor) {
                                manager.switchTo(profile)
                            }
                        }
                        if manager.profiles.count > 1 {
                            SettingsIconButton(icon: "trash", color: .red, action: {
                                manager.removeProfile(profile)
                            })
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
            }
            
            SettingsCard(title: "Natpis Islanda") {
                TextField("Alexandria", text: $islandTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                    .onChange(of: islandTitle) { _, newValue in
                        AppSettings.islandTitle = newValue
                    }
            }
            
            SettingsCard(title: "Search panel") {
                Picker("Pozicija", selection: $searchPanelPositionRaw) {
                    ForEach(SearchPanelPosition.allCases, id: \.rawValue) { position in
                        Text(position.label).tag(position.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            SettingsCard(title: "Pri pokretanju i novi tab") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Što se otvori kad se pokrene aplikacija i kad stisneš „Novi tab” (automatski otvori pretragu / web preglednik, prazno ili Dev Mode)")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Picker("", selection: $onOpenActionRaw) {
                        ForEach(OnOpenAction.allCases, id: \.rawValue) { action in
                            Text(action.label).tag(action.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            InstalledAppsSettingsCard(accentColor: accentColor)
        }
    }
}

// MARK: - Instalirane aplikacije – brisanje svih
private struct InstalledAppsSettingsCard: View {
    @ObservedObject private var installService = AppInstallService.shared
    let accentColor: Color
    @State private var showConfirmDeleteAll = false
    
    var body: some View {
        SettingsCard(title: "Instalirane aplikacije") {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(installService.installedApps.count) aplikacija u biblioteci.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                if !installService.installedApps.isEmpty {
                    Button {
                        showConfirmDeleteAll = true
                    } label: {
                        Text("Obriši sve")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.red.opacity(0.9)))
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Obrisati sve instalirane aplikacije?", isPresented: $showConfirmDeleteAll, titleVisibility: .visible) {
                        Button("Obriši sve", role: .destructive) {
                            installService.uninstallAll()
                        }
                        Button("Odustani", role: .cancel) { }
                    } message: {
                        Text("Ne može se poništiti. Folderi aplikacija bit će uklonjeni.")
                    }
                }
            }
        }
    }
}

// MARK: - Server za pretragu aplikacija (bilo koja webapp s podržanim API-jem)
private struct SearchEnginesSettingsSection: View {
    @ObservedObject private var engineManager = SearchEngineManager.shared
    @State private var showAddEngine = false
    @State private var newEngineName = ""
    @State private var newEngineURL = "http://localhost:3847"
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Pretraga aplikacija")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Server kataloga") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dodaj URL bilo koje webapp koja servira katalog aplikacija (isti API). Alexandria se spaja na odabrani server.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if engineManager.engines.isEmpty {
                        Text("Nema dodanog servera. Dodaj ispod.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 8)
                    }
                    
                    ForEach(engineManager.engines) { engine in
                        HStack(spacing: 12) {
                            Button {
                                engineManager.select(engine)
                            } label: {
                                Image(systemName: engineManager.selectedEngineId == engine.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(engineManager.selectedEngineId == engine.id ? accentColor : .white.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(engine.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text(engine.url)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            if engineManager.engines.count > 1 {
                                Button {
                                    engineManager.remove(engine)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.9))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(engineManager.selectedEngineId == engine.id ? accentColor.opacity(0.12) : Color.white.opacity(0.06))
                        )
                    }
                    
                    Button {
                        newEngineName = ""
                        newEngineURL = "http://localhost:3847"
                        showAddEngine = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Dodaj server")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showAddEngine) {
            AddSearchEngineSheet(
                name: $newEngineName,
                url: $newEngineURL,
                accentColor: accentColor,
                onSave: {
                    guard !newEngineName.trimmingCharacters(in: .whitespaces).isEmpty,
                          !newEngineURL.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    engineManager.add(name: newEngineName.trimmingCharacters(in: .whitespaces), url: newEngineURL.trimmingCharacters(in: .whitespaces))
                    showAddEngine = false
                },
                onCancel: { showAddEngine = false }
            )
        }
    }
}

// MARK: - Sheet za dodavanje servera kataloga
private struct AddSearchEngineSheet: View {
    @Binding var name: String
    @Binding var url: String
    let accentColor: Color
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Dodaj server")
                .font(.title2.bold())
                .foregroundColor(accentColor)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Naziv")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                TextField("npr. Moj katalog", text: $name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                TextField("http://localhost:3847", text: $url)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
            }
            
            HStack(spacing: 12) {
                Button("Odustani") {
                    onCancel()
                }
                .foregroundColor(.white.opacity(0.8))
                .buttonStyle(.plain)
                Spacer()
                Button("Spremi") {
                    onSave()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(accentColor))
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(Color.black.opacity(0.9))
    }
}

// MARK: - Izgled / Tema
private struct AppearanceSettingsSection: View {
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    let accentColor: Color
    
    private var appTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue; AppSettings.appTheme = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Izgled")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Tema") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Odaberi izgled aplikacije")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                            SettingsThemeButton(
                                theme: theme,
                                isSelected: appTheme.wrappedValue == theme,
                                accentColor: accentColor
                            ) {
                                appTheme.wrappedValue = theme
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Gumb za odabir teme
private struct SettingsThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: theme.icon)
                    .font(.system(size: 20))
                Text(theme.label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor : accentColor.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mreža / Internet
private struct NetworkSettingsSection: View {
    @AppStorage("isInternetEnabled") private var isInternetEnabled = true
    @ObservedObject private var networkMonitor = NetworkMonitorService.shared
    @State private var serverTestURL = "https://www.apple.com"
    @State private var serverTestStatus: ServerTestStatus = .idle
    let accentColor: Color
    
    enum ServerTestStatus: Equatable {
        case idle
        case testing
        case success(Int)
        case error(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Mreža")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Internet") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Dozvoli spajanje na internet", isOn: $isInternetEnabled)
                        .toggleStyle(.switch)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 24))
                            .foregroundColor(globeColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(statusText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            Text(statusDetail)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
            }
            
            SettingsCard(title: "Test servera") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unesi URL servera da provjeriš spajanje")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        TextField("https://example.com", text: $serverTestURL)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                        
                        Button {
                            testServerConnection()
                        } label: {
                            Group {
                                if serverTestStatus == .testing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text("Testiraj")
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .frame(width: 70)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(accentColor))
                        }
                        .buttonStyle(.plain)
                        .disabled(serverTestStatus == .testing || serverTestURL.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    serverTestResultView
                }
            }
        }
    }
    
    @ViewBuilder
    private var serverTestResultView: some View {
        switch serverTestStatus {
        case .idle:
            EmptyView()
        case .testing:
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(accentColor)
                Text("Spajam...")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
        case .success(let statusCode):
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "22c55e"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spojeno")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text("HTTP \(statusCode)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "22c55e").opacity(0.15)))
        case .error(let message):
            HStack(spacing: 10) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Greška")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.15)))
        }
    }
    
    private func testServerConnection() {
        let urlString = serverTestURL.trimmingCharacters(in: .whitespaces)
        guard !urlString.isEmpty,
              var components = URLComponents(string: urlString) else {
            serverTestStatus = .error("Neispravan URL")
            return
        }
        if components.scheme == nil {
            components.scheme = "https"
        }
        guard let url = components.url else {
            serverTestStatus = .error("Neispravan URL")
            return
        }
        
        serverTestStatus = .testing
        Task {
            do {
                let (_, response) = try await BrowserNetworkingService.shared.fetch(url: url)
                if let http = response as? HTTPURLResponse {
                    await MainActor.run {
                        serverTestStatus = .success(http.statusCode)
                    }
                } else {
                    await MainActor.run {
                        serverTestStatus = .success(200)
                    }
                }
            } catch {
                await MainActor.run {
                    serverTestStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private var globeColor: Color {
        guard isInternetEnabled else { return .gray }
        switch networkMonitor.status {
        case .connected: return Color(hex: "22c55e")
        case .disconnected: return .gray
        case .unknown: return .orange
        }
    }
    
    private var statusText: String {
        guard isInternetEnabled else { return "Internet isključen" }
        switch networkMonitor.status {
        case .connected: return "Spojeno"
        case .disconnected: return "Nije spojeno"
        case .unknown: return "Provjeravam..."
        }
    }
    
    private var statusDetail: String {
        guard isInternetEnabled else { return "Uključite u postavkama za pristup mreži." }
        switch networkMonitor.status {
        case .connected: return "Mreža aktivna"
        case .disconnected: return "Nema dostupne konekcije"
        case .unknown: return "Provjera statusa"
        }
    }
}

// MARK: - Privatnost
private struct PrivacySettingsSection: View {
    @Binding var isIncognito: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Privatnost")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Pregledavanje") {
                Toggle("Incognito mode", isOn: $isIncognito)
                    .toggleStyle(.switch)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Sigurnost
private struct SecuritySettingsSection: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Sigurnost")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Sigurnosne postavke") {
                Text("Capability-based permissions, app signing, zero-trust – u izradi.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - O pregledniku
private struct AboutSettingsSection: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("O pregledniku")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            SettingsCard(title: "Alexandria") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alexandria 1.0")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Swift app browser – brušeno staklo, Alexandria Swift.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Gumbi u postavkama
private struct SettingsPrimaryButton: View {
    let title: String
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(accentColor)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsIconButton: View {
    let icon: String
    var color: Color = Color(hex: "ff5c00")
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings kartica
private struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            content()
        }
        .padding(20)
        .frame(maxWidth: 500, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
