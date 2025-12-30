//
//  TreeStorageService.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import Foundation

/// Notification ime za osvježavanje liste stabala
extension Notification.Name {
    static let treeListDidUpdate = Notification.Name("treeListDidUpdate")
}

/// Servis za spremanje i učitavanje binarnih stabala odluke u JSON formatu
class TreeStorageService {
    static let shared = TreeStorageService()
    
    /// Folder gdje se spremaju stabla
    private var treesDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let treesFolder = documentsPath.appendingPathComponent("TreeOfChoice/Trees", isDirectory: true)
        
        // Kreiraj folder ako ne postoji
        if !FileManager.default.fileExists(atPath: treesFolder.path) {
            try? FileManager.default.createDirectory(at: treesFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        return treesFolder
    }
    
    private init() {}
    
    // MARK: - Save Tree
    
    /// Sprema stablo u JSON datoteku u trees folderu
    func saveTree(_ tree: DecisionTreeItem) throws -> URL {
        var fileName = sanitizeFileName(tree.name) + ".json"
        var fileURL = treesDirectory.appendingPathComponent(fileName)
        
        // Ako datoteka već postoji, dodaj timestamp
        var counter = 1
        while FileManager.default.fileExists(atPath: fileURL.path) {
            let nameWithoutExt = sanitizeFileName(tree.name)
            fileName = "\(nameWithoutExt)_\(counter).json"
            fileURL = treesDirectory.appendingPathComponent(fileName)
            counter += 1
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(tree)
        try data.write(to: fileURL)
        
        // Pošalji notification da je lista stabala ažurirana
        NotificationCenter.default.post(name: .treeListDidUpdate, object: nil)
        
        return fileURL
    }
    
    // MARK: - Load Trees
    
    /// Učitava sva stabla iz trees foldera
    func loadAllTrees() throws -> [DecisionTreeItem] {
        let files = try FileManager.default.contentsOfDirectory(
            at: treesDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        
        var trees: [DecisionTreeItem] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for fileURL in jsonFiles {
            do {
                let data = try Data(contentsOf: fileURL)
                let tree = try decoder.decode(DecisionTreeItem.self, from: data)
                trees.append(tree)
            } catch {
                print("Error loading tree from \(fileURL.lastPathComponent): \(error)")
                // Nastavi s drugim fajlovima ako jedan ne uspije
            }
        }
        
        // Sortiraj po datumu kreiranja (najnovije prvo)
        return trees.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// Učitava stablo iz JSON datoteke
    func loadTree(from url: URL) throws -> DecisionTreeItem {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DecisionTreeItem.self, from: data)
    }
    
    // MARK: - Delete Tree
    
    /// Briše stablo (JSON datoteku)
    func deleteTree(_ tree: DecisionTreeItem) throws {
        // Pronađi datoteku koja sadrži ovo stablo (po ID-u)
        let files = try FileManager.default.contentsOfDirectory(
            at: treesDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        
        // Pronađi datoteku koja sadrži stablo s istim ID-om
        for fileURL in jsonFiles {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loadedTree = try decoder.decode(DecisionTreeItem.self, from: data)
                
                // Ako je ID isti, ovo je datoteka koju trebamo obrisati
                if loadedTree.id == tree.id {
                    try FileManager.default.removeItem(at: fileURL)
                    // Pošalji notification da je lista stabala ažurirana
                    NotificationCenter.default.post(name: .treeListDidUpdate, object: nil)
                    return
                }
            } catch {
                // Nastavi s drugom datotekom ako ova ne može biti dekodirana
                continue
            }
        }
        
        // Ako datoteka nije pronađena, baci grešku
        throw NSError(domain: "TreeStorageService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tree file not found"])
    }
    
    /// Briše stablo po URL-u
    func deleteTree(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
            // Pošalji notification da je lista stabala ažurirana
            NotificationCenter.default.post(name: .treeListDidUpdate, object: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Sanitizira ime datoteke (uklanja nedozvoljene znakove)
    private func sanitizeFileName(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>")
        return name.components(separatedBy: invalidCharacters).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Vraća URL foldera gdje se spremaju stabla
    func getTreesDirectoryURL() -> URL {
        return treesDirectory
    }
}

