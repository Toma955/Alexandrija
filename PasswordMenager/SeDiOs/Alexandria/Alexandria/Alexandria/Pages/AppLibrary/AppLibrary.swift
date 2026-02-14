//
//  AppLibrary.swift
//  Alexandria
//
//  App Library – knjižnica aplikacija. Import .zip, lista, otvaranje.
//

import SwiftUI
import UniformTypeIdentifiers

struct AppLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var installService = AppInstallService.shared
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showImportError = false
    
    var onOpenApp: ((InstalledApp) -> Void)?
    private let accentColor = Color(hex: "ff5c00")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("App Library")
                    .font(.title2.bold())
                    .foregroundColor(accentColor)
                Spacer()
                Button {
                    isImporting = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import .zip")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(accentColor))
                }
                .buttonStyle(.plain)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Lista aplikacija
            if installService.installedApps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 48))
                        .foregroundColor(accentColor.opacity(0.6))
                    Text("Nema instaliranih aplikacija")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text("Ovdje su samo aplikacije koje si instalirao (iz Pretrage ili Import .zip).")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Text("Povuci .zip ovdje ili klikni Import")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.zip, .fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(installService.installedApps) { app in
                            AppLibraryRow(
                                app: app,
                                accentColor: accentColor,
                                onOpen: {
                                    dismiss()
                                    onOpenApp?(app)
                                },
                                onUninstall: {
                                    installService.uninstall(app)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.zip, .fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            }
        }
        .frame(width: 560, height: 440)
        .background(Color.black.opacity(0.9))
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importZip(from: url)
            case .failure(let error):
                importError = error.localizedDescription
                showImportError = true
            }
        }
        .alert("Greška pri importu", isPresented: $showImportError) {
            Button("OK") { showImportError = false }
        } message: {
            if let err = importError { Text(err) }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "zip" else { return }
                DispatchQueue.main.async {
                    importZipFromDrop(url)
                }
            }
        }
    }
    
    private func importZipFromDrop(_ url: URL) {
        do {
            _ = try AppInstallService.shared.install(from: url)
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }
    
    private func importZip(from url: URL) {
        do {
            _ = try AppInstallService.shared.install(fromSecurityScopedURL: url)
        } catch {
            importError = error.localizedDescription
            showImportError = true
        }
    }
}

// MARK: - Red u listi aplikacija
private struct AppLibraryRow: View {
    let app: InstalledApp
    let accentColor: Color
    let onOpen: () -> Void
    let onUninstall: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 28))
                .foregroundColor(accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(app.entryPoint)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button {
                onOpen()
            } label: {
                Text("Otvori")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(accentColor))
            }
            .buttonStyle(.plain)
            
            Button {
                onUninstall()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    AppLibraryView()
}
