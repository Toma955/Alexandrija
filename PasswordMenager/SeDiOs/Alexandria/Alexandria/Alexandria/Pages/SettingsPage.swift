//
//  SettingsPage.swift
//  Alexandria
//
//  Postavke – lijevi sidebar od brušenog stakla, grupe: Postavke (tabovi, island, izgled, …) i Market (plug-ini, fontovi, teme, …).
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Jedna stavka u sidebaru
private struct SettingsSidebarItem: Identifiable {
    let id: String
    let title: String
    let icon: String
}

// MARK: - Grupa u sidebaru (Postavke / Market)
private struct SettingsSidebarGroup: Identifiable {
    let id: String
    let title: String
    let items: [SettingsSidebarItem]
}

// MARK: - Odabrana sekcija (raw value = id stavke)
private enum SettingsSection: String, CaseIterable {
    case workModes
    case general
    case savjeti
    case izlazak
    case createNewAccount
    case digitalLife
    case tabs
    case island
    case appearance
    case tabBarLayout
    case languageAndFont
    case security
    case limitsAndPermissions
    case paymentAndAccounts
    case designCoverage
    case designAppLaunch
    case designIsland
    case designTabs
    case designThemes
    case swift
    case downloads
    case connectionStatus
    case devToolsDisplay
    case vpn
    case securityAgent
    case networkTraffic
    case devTools
    case plugins
    case fonts
    case widgets
    case themes
    case languages
}

private extension SettingsSection {
    static var postavkeGroups: [SettingsSidebarGroup] {
        [
            SettingsSidebarGroup(
                id: "generalne-postavke",
                title: "Generalne postavke",
                items: [
                    SettingsSidebarItem(id: SettingsSection.workModes.rawValue, title: "Modovi", icon: "square.grid.2x2"),
                    SettingsSidebarItem(id: SettingsSection.general.rawValue, title: "Općenito", icon: "gearshape.fill"),
                    SettingsSidebarItem(id: SettingsSection.tabs.rawValue, title: "Postavke tabova", icon: "square.stack.3d.up"),
                    SettingsSidebarItem(id: SettingsSection.island.rawValue, title: "Postavke Islanda", icon: "capsule"),
                    SettingsSidebarItem(id: SettingsSection.appearance.rawValue, title: "Postavke izgleda", icon: "paintbrush.fill"),
                    SettingsSidebarItem(id: SettingsSection.tabBarLayout.rawValue, title: "Raspored trake", icon: "rectangle.topthird.inset.filled"),
                    SettingsSidebarItem(id: SettingsSection.languageAndFont.rawValue, title: "Jezik i font", icon: "textformat"),
                    SettingsSidebarItem(id: SettingsSection.paymentAndAccounts.rawValue, title: "Plaćanje i korisnički računi", icon: "creditcard.and.123"),
                    SettingsSidebarItem(id: SettingsSection.downloads.rawValue, title: "Preuzimanja", icon: "arrow.down.circle"),
                    SettingsSidebarItem(id: SettingsSection.connectionStatus.rawValue, title: "Status spajanja", icon: "antenna.radiowaves.left.and.right"),
                    SettingsSidebarItem(id: SettingsSection.devToolsDisplay.rawValue, title: "Dev Tools prikaz", icon: "rectangle.split.2x2")
                ]
            ),
            SettingsSidebarGroup(
                id: "account",
                title: "Account",
                items: [
                    SettingsSidebarItem(id: SettingsSection.createNewAccount.rawValue, title: "Create new account", icon: "person.badge.plus"),
                    SettingsSidebarItem(id: SettingsSection.digitalLife.rawValue, title: "Digital Life", icon: "heart.text.square.fill")
                ]
            ),
            SettingsSidebarGroup(
                id: "sigurnost",
                title: "Sigurnost",
                items: [
                    SettingsSidebarItem(id: SettingsSection.security.rawValue, title: "Sigurnost", icon: "checkmark.shield.fill"),
                    SettingsSidebarItem(id: SettingsSection.limitsAndPermissions.rawValue, title: "Ograničenja i dozvole", icon: "slider.horizontal.3")
                ]
            ),
            SettingsSidebarGroup(
                id: "dizajn",
                title: "Dizajn",
                items: [
                    SettingsSidebarItem(id: SettingsSection.designThemes.rawValue, title: "Teme", icon: "paintpalette.fill"),
                    SettingsSidebarItem(id: SettingsSection.designIsland.rawValue, title: "Dizajn Islanda", icon: "capsule.fill"),
                    SettingsSidebarItem(id: SettingsSection.designTabs.rawValue, title: "Dizajn tabova", icon: "square.stack.3d.up.fill"),
                    SettingsSidebarItem(id: SettingsSection.designAppLaunch.rawValue, title: "Pokretanje aplikacije", icon: "play.circle")
                ]
            ),
            SettingsSidebarGroup(
                id: "swift",
                title: "Swift",
                items: [
                    SettingsSidebarItem(id: SettingsSection.swift.rawValue, title: "Verzija i biblioteke", icon: "chevron.left.forwardslash.chevron.right")
                ]
            ),
            SettingsSidebarGroup(
                id: "ugradene",
                title: "Ugrađene aplikacije",
                items: [
                    SettingsSidebarItem(id: SettingsSection.vpn.rawValue, title: "VPN", icon: "network"),
                    SettingsSidebarItem(id: SettingsSection.securityAgent.rawValue, title: "Security agent", icon: "shield.checkered"),
                    SettingsSidebarItem(id: SettingsSection.networkTraffic.rawValue, title: "Network data traffic", icon: "chart.bar.doc.horizontal"),
                    SettingsSidebarItem(id: SettingsSection.devTools.rawValue, title: "Dev tools", icon: "wrench.and.screwdriver")
                ]
            ),
            SettingsSidebarGroup(
                id: "savjeti",
                title: "Savjeti",
                items: [
                    SettingsSidebarItem(id: SettingsSection.savjeti.rawValue, title: "Savjeti", icon: "lightbulb.fill")
                ]
            ),
            SettingsSidebarGroup(
                id: "izlazak",
                title: "Izlazak",
                items: [
                    SettingsSidebarItem(id: SettingsSection.izlazak.rawValue, title: "Izlazak", icon: "rectangle.portrait.and.arrow.right")
                ]
            )
        ]
    }

    static var marketGroups: [SettingsSidebarGroup] {
        [
            SettingsSidebarGroup(
                id: "market",
                title: "Market",
                items: [
                    SettingsSidebarItem(id: SettingsSection.plugins.rawValue, title: "Plug-ini", icon: "puzzlepiece.extension"),
                    SettingsSidebarItem(id: SettingsSection.fonts.rawValue, title: "Fontovi", icon: "textformat"),
                    SettingsSidebarItem(id: SettingsSection.widgets.rawValue, title: "Widgeti", icon: "square.grid.2x2"),
                    SettingsSidebarItem(id: SettingsSection.themes.rawValue, title: "Teme", icon: "paintpalette"),
                    SettingsSidebarItem(id: SettingsSection.languages.rawValue, title: "Jezici", icon: "globe")
                ]
            )
        ]
    }
}

struct SettingsView: View {
    var onClose: () -> Void
    @State private var selectedSection: SettingsSection = .general
    @ObservedObject private var manager = ProfileManager.shared
    @AppStorage("searchPanelPosition") private var searchPanelPositionRaw = SearchPanelPosition.both.rawValue
    @AppStorage("isIncognito") private var isIncognito = false
    @State private var showAddProfile = false
    @AppStorage("killerSwitchEnabled") private var killerSwitchEnabled = false

    private var accentColor: Color { AlexandriaTheme.accentColor }
    private static let sidebarWidth: CGFloat = 260
    private static let sidebarCornerRadius: CGFloat = 20

    var body: some View {
        ZStack {
            AppBackgroundView()
                .ignoresSafeArea()

            HStack(spacing: 0) {
                // Lijevi sidebar – brušeno staklo, zaobljen
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentColor)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(accentColor.opacity(0.2)))
                        }
                        .buttonStyle(.plain)
                        Text("Postavke")
                            .font(.title2.bold())
                            .foregroundColor(accentColor)
                    }
                    .padding(20)

                    Divider()
                        .background(Color.primary.opacity(0.15))
                        .padding(.horizontal, 16)

                    // Killer switch – na početku
                    killerSwitchButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Generalne postavke (Općenito + tabovi, island, izgled, …)
                            if let first = SettingsSection.postavkeGroups.first {
                                sidebarGroupView(first)
                                    .padding(.bottom, 16)
                            }

                            // Account (Create new account, Digital Life)
                            if SettingsSection.postavkeGroups.indices.contains(1) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[1])
                                    .padding(.bottom, 16)
                            }

                            // Sigurnost
                            if SettingsSection.postavkeGroups.indices.contains(2) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[2])
                                    .padding(.bottom, 16)
                            }

                            // Dizajn
                            if SettingsSection.postavkeGroups.indices.contains(3) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[3])
                                    .padding(.bottom, 16)
                            }

                            // Swift
                            if SettingsSection.postavkeGroups.indices.contains(4) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[4])
                                    .padding(.bottom, 16)
                            }

                            // Ugrađene aplikacije
                            if SettingsSection.postavkeGroups.indices.contains(5) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[5])
                                    .padding(.bottom, 16)
                            }

                            // Savjeti (odvojeno)
                            if SettingsSection.postavkeGroups.indices.contains(6) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[6])
                                    .padding(.bottom, 16)
                            }

                            // Izlazak (na dnu)
                            if SettingsSection.postavkeGroups.indices.contains(7) {
                                sidebarNestedGroupView(SettingsSection.postavkeGroups[7])
                                    .padding(.bottom, 20)
                            }

                            Divider()
                                .background(Color.primary.opacity(0.2))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 16)

                            // Grupa Market
                            ForEach(SettingsSection.marketGroups) { group in
                                sidebarGroupView(group)
                            }
                        }
                        .padding(16)
                    }

                    Spacer(minLength: 0)
                }
                .frame(width: Self.sidebarWidth)
                .background(
                    RoundedRectangle(cornerRadius: Self.sidebarCornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Self.sidebarCornerRadius)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .padding(.leading, 16)
                .padding(.vertical, 16)

                // Sadržaj desno
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        settingsContent
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.25))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showAddProfile) {
            AddProfileView(onDismiss: { showAddProfile = false })
        }
    }

    @ViewBuilder
    private func sidebarGroupView(_ group: SettingsSidebarGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)

            VStack(spacing: 4) {
                ForEach(group.items) { item in
                    Button {
                        if let section = SettingsSection(rawValue: item.id) {
                            selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .font(.system(size: 14))
                                .frame(width: 22, alignment: .center)
                            Text(item.title)
                                .font(.system(size: 14, weight: selectedSection.rawValue == item.id ? .semibold : .regular))
                        }
                        .foregroundColor(selectedSection.rawValue == item.id ? accentColor : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSection.rawValue == item.id ? accentColor.opacity(0.15) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Killer switch – uvijek crveni s bijelim slovima, ne mijenja se s temom.
    private var killerSwitchButton: some View {
        Button {
            killerSwitchEnabled.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: killerSwitchEnabled ? "checkmark.shield.fill" : "shield.slash")
                    .font(.system(size: 16))
                Text("Killer switch")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(killerSwitchEnabled ? Color.red : Color.red.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sidebarNestedGroupView(_ group: SettingsSidebarGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 12)
                .padding(.top, 12)
            VStack(spacing: 4) {
                ForEach(group.items) { item in
                    HStack(spacing: 10) {
                        Button {
                            if let section = SettingsSection(rawValue: item.id) {
                                selectedSection = section
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .frame(width: 22, alignment: .center)
                                Text(item.title)
                                    .font(.system(size: 14, weight: selectedSection.rawValue == item.id ? .semibold : .regular))
                            }
                            .foregroundColor(selectedSection.rawValue == item.id ? accentColor : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, group.id == "ugradene" ? 8 : 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedSection.rawValue == item.id ? accentColor.opacity(0.15) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        if group.id == "ugradene" {
                            BuiltInAppStatusButtonView(appId: item.id)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.thickMaterial)
                .opacity(0.98)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch selectedSection {
        case .workModes:
            WorkModesSettingsSection(accentColor: accentColor)
        case .general:
            GeneralSettingsSection(
                showAddProfile: $showAddProfile,
                manager: manager,
                accentColor: accentColor
            )
        case .savjeti:
            PlaceholderSettingsSection(title: "Savjeti", message: "Korisni savjeti za korištenje aplikacije – uskoro.", accentColor: accentColor)
        case .izlazak:
            PlaceholderSettingsSection(title: "Izlazak", message: "Izlazak iz računa ili zatvaranje aplikacije – uskoro.", accentColor: accentColor)
        case .createNewAccount:
            CreateNewAccountSection(manager: manager, accentColor: accentColor)
        case .digitalLife:
            PlaceholderSettingsSection(title: "Digital Life", message: "Digital Life – uskoro nešto zanimljivo.", accentColor: accentColor)
        case .tabs:
            TabsSettingsSection(accentColor: accentColor)
        case .island:
            IslandSettingsSection(searchPanelPositionRaw: $searchPanelPositionRaw, accentColor: accentColor)
        case .appearance:
            AppearanceSettingsSection(accentColor: accentColor)
        case .tabBarLayout:
            PlaceholderSettingsSection(title: "Raspored trake", message: "Položaj i redoslijed elemenata u traci – u izradi.", accentColor: accentColor)
        case .languageAndFont:
            LanguageAndFontSettingsSection(accentColor: accentColor)
        case .security:
            SecuritySettingsSection(accentColor: accentColor)
        case .limitsAndPermissions:
            LimitsAndPermissionsSettingsSection(accentColor: accentColor)
        case .designCoverage:
            DesignCoverageSettingsSection(accentColor: accentColor)
        case .designAppLaunch:
            DesignAppLaunchSettingsSection(accentColor: accentColor)
        case .designIsland:
            DesignIslandSettingsSection(accentColor: accentColor)
        case .designTabs:
            DesignTabsSettingsSection(accentColor: accentColor)
        case .designThemes:
            DesignThemesSettingsSection(accentColor: accentColor)
        case .swift:
            SwiftSettingsSection(accentColor: accentColor)
        case .downloads:
            DownloadsSettingsSection(accentColor: accentColor)
        case .connectionStatus:
            ConnectionStatusSettingsSection(accentColor: accentColor)
        case .devToolsDisplay:
            DevToolsDisplaySettingsSection(accentColor: accentColor)
        case .paymentAndAccounts:
            PaymentAndAccountsSettingsSection(accentColor: accentColor)
        case .vpn:
            BuiltInAppSettingsSection(appId: "vpn", title: "VPN", icon: "network", subtitle: "Virtualna privatna mreža – tuneliranje i zaštita prometa.", accentColor: accentColor)
        case .securityAgent:
            BuiltInAppSettingsSection(appId: "securityAgent", title: "Security agent", icon: "shield.checkered", subtitle: "Zaštita u realnom vremenu, detekcija prijetnji.", accentColor: accentColor)
        case .networkTraffic:
            NetworkTrafficSettingsSection(accentColor: accentColor)
        case .devTools:
            BuiltInAppSettingsSection(appId: "devTools", title: "Dev tools", icon: "wrench.and.screwdriver", subtitle: "Alati za razvoj – konzola, inspektor, debug.", accentColor: accentColor)
        case .plugins:
            MarketPluginsSettingsSection(accentColor: accentColor)
        case .fonts:
            MarketFontsSettingsSection(accentColor: accentColor)
        case .widgets:
            PlaceholderSettingsSection(title: "Widgeti", message: "Widgeti za traku i Island – u izradi.", accentColor: accentColor)
        case .themes:
            MarketThemesSettingsSection(accentColor: accentColor)
        case .languages:
            MarketLanguagesSettingsSection(accentColor: accentColor)
        }
    }
}

// MARK: - Placeholder sekcija (u izradi)
private struct PlaceholderSettingsSection: View {
    let title: String
    let message: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: title) {
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Jezik i font
private struct LanguageAndFontSettingsSection: View {
    @ObservedObject private var catalogService = BackendCatalogService.shared
    let accentColor: Color

    private var availableLanguages: [InterfaceLanguage] {
        InterfaceLanguage.available()
    }

    private var selectedLocaleBinding: Binding<String> {
        Binding(
            get: { AppSettings.interfaceLocaleCode },
            set: { AppSettings.interfaceLocaleCode = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Jezik i font")
                .font(.title.bold())
                .foregroundColor(accentColor)

            SettingsCard(title: "Jezik sučelja") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Uvijek je odabran jedan jezik. Zadano je Hrvatski. Dodatne jezike preuzmi u Market → Jezici.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Picker("Jezik", selection: selectedLocaleBinding) {
                        ForEach(availableLanguages) { lang in
                            Text(lang.displayName).tag(lang.localeCode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    if availableLanguages.isEmpty {
                        Text("Nema dostupnih jezika.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            SettingsCard(title: "Font") {
                Text("Odabir fonta za sučelje – u izradi.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Market – Teme (pretraga, katalog, preuzete s veličinom)
private struct MarketThemesSettingsSection: View {
    @ObservedObject private var catalogService = BackendCatalogService.shared
    @AppStorage("themeRegistrySelectedThemeId") private var selectedThemeId: String = "default"
    @State private var themeSearchQuery: String = ""
    let accentColor: Color

    private var catalogThemes: [RemoteThemeItem] {
        let list = catalogService.catalog?.themes ?? []
        let q = themeSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return list }
        return list.filter {
            $0.name.lowercased().contains(q) || ($0.description?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Teme")
                .font(.title.bold())
                .foregroundColor(accentColor)

            // Tražilica za teme
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                TextField("Traži teme…", text: $themeSearchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

            // Katalog tema (s backenda)
            SettingsCard(title: "Katalog tema") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Teme s backenda. Postavi Server kataloga u Status spajanja.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 12) {
                        Button {
                            Task { await catalogService.fetchCatalog() }
                        } label: {
                            HStack(spacing: 6) {
                                if catalogService.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(catalogService.isSyncing ? "Osvježavam…" : "Osvježi katalog")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(catalogService.isSyncing)
                        if let date = catalogService.lastSyncDate {
                            Text("Zadnje: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        if let err = catalogService.lastError {
                            Text(err)
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.9))
                                .lineLimit(2)
                        }
                        Spacer()
                    }
                    ForEach(catalogThemes) { item in
                        MarketCatalogRow(
                            title: item.name,
                            subtitle: item.description,
                            isInstalled: catalogService.installedThemeIdsSnapshot.contains(item.id),
                            isDownloading: catalogService.downloadingThemeIds.contains(item.id),
                            accentColor: accentColor,
                            onInstall: {
                                Task { _ = try? await catalogService.downloadTheme(item) }
                            },
                            onRemove: nil
                        )
                    }
                    if catalogThemes.isEmpty && !catalogService.isSyncing {
                        Text("Nema tema u katalogu ili nema rezultata za pretragu. Osvježi katalog.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            // Preuzete teme (s veličinom i ukloni)
            SettingsCard(title: "Preuzete teme") {
                VStack(alignment: .leading, spacing: 8) {
                    let installed = catalogService.installedThemeInfos()
                    if installed.isEmpty {
                        Text("Nema preuzetih tema. Preuzmi temu iz kataloga iznad.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        ForEach(installed) { theme in
                            InstalledThemeRow(
                                themeId: theme.id,
                                displayName: theme.displayName,
                                sizeBytes: catalogService.themeDirectorySize(id: theme.id),
                                accentColor: accentColor,
                                onRemove: {
                                    if selectedThemeId == theme.id { selectedThemeId = "default" }
                                    catalogService.removeTheme(id: theme.id)
                                }
                            )
                        }
                    }
                }
            }
        }
        .onAppear { catalogService.refreshCatalogIfStale() }
    }
}

// MARK: - Red preuzete teme (ime, veličina, Ukloni)
private struct InstalledThemeRow: View {
    let themeId: String
    let displayName: String
    let sizeBytes: Int64?
    let accentColor: Color
    let onRemove: () -> Void

    private var sizeText: String {
        guard let bytes = sizeBytes, bytes >= 0 else { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(sizeText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Button("Ukloni") {
                onRemove()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(accentColor)
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
    }
}

// MARK: - Market – Jezici
private struct MarketLanguagesSettingsSection: View {
    @ObservedObject private var catalogService = BackendCatalogService.shared
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Jezici")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Jezični paketi") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Osvježi katalog") {
                        Task { await catalogService.fetchCatalog() }
                    }
                    .foregroundColor(accentColor)
                    .disabled(catalogService.isSyncing)
                    ForEach(catalogService.catalog?.languages ?? []) { item in
                        MarketCatalogRow(
                            title: item.name,
                            subtitle: item.locale,
                            isInstalled: catalogService.installedLanguageIdsSnapshot.contains(item.id),
                            isDownloading: catalogService.downloadingLanguageIds.contains(item.id),
                            accentColor: accentColor,
                            onInstall: {
                                Task { _ = try? await catalogService.downloadLanguage(item) }
                            },
                            onRemove: { catalogService.removeLanguage(id: item.id) }
                        )
                    }
                    if (catalogService.catalog?.languages ?? []).isEmpty {
                        Text("Nema jezičnih paketa u katalogu.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .onAppear { catalogService.refreshCatalogIfStale() }
    }
}

// MARK: - Market – Plug-ini
private struct MarketPluginsSettingsSection: View {
    @ObservedObject private var catalogService = BackendCatalogService.shared
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Plug-ini")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Dodaci i proširenja") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Osvježi katalog") {
                        Task { await catalogService.fetchCatalog() }
                    }
                    .foregroundColor(accentColor)
                    .disabled(catalogService.isSyncing)
                    ForEach(catalogService.catalog?.plugins ?? []) { item in
                        MarketCatalogRow(
                            title: item.name,
                            subtitle: item.description,
                            isInstalled: catalogService.installedPluginIdsSnapshot.contains(item.id),
                            isDownloading: catalogService.downloadingPluginIds.contains(item.id),
                            accentColor: accentColor,
                            onInstall: {
                                Task { _ = try? await catalogService.downloadPlugin(item) }
                            },
                            onRemove: { catalogService.removePlugin(id: item.id) }
                        )
                    }
                    if (catalogService.catalog?.plugins ?? []).isEmpty {
                        Text("Nema plug-ina u katalogu.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .onAppear { catalogService.refreshCatalogIfStale() }
    }
}

// MARK: - Market – Fontovi
private struct MarketFontsSettingsSection: View {
    @ObservedObject private var catalogService = BackendCatalogService.shared
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Fontovi")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Dostupni fontovi") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Osvježi katalog") {
                        Task { await catalogService.fetchCatalog() }
                    }
                    .foregroundColor(accentColor)
                    .disabled(catalogService.isSyncing)
                    ForEach(catalogService.catalog?.fonts ?? []) { item in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                if let sub = item.description, !sub.isEmpty {
                                    Text(sub)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                    }
                    if (catalogService.catalog?.fonts ?? []).isEmpty && !catalogService.isSyncing {
                        Text("Nema fontova u katalogu.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .onAppear { catalogService.refreshCatalogIfStale() }
    }
}

// MARK: - Jedna stavka u Market katalogu (Preuzmi / Preuzimam… / Preuzeto / Ukloni)
private struct MarketCatalogRow: View {
    let title: String
    let subtitle: String?
    let isInstalled: Bool
    let isDownloading: Bool
    let accentColor: Color
    let onInstall: () -> Void
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            Spacer()
            if isDownloading {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                    Text("Preuzimam…")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if isInstalled {
                HStack(spacing: 10) {
                    Text("Preuzeto")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    if let onRemove = onRemove {
                        Button("Ukloni") {
                            onRemove()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button("Preuzmi") {
                    onInstall()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(accentColor)
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
    }
}

// MARK: - Pokrivanje u dizajnu
private struct DesignCoverageSettingsSection: View {
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Pokrivanje u dizajnu")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Dizajn sustav") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pokrivanje komponenti, stilova i pristupačnosti u dizajnu aplikacije.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text("U izradi.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
        }
    }
}

// MARK: - Dizajn: Pokretanje aplikacije
private struct DesignAppLaunchSettingsSection: View {
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Pokretanje aplikacije")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Izgled pri pokretanju") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Splash ekran, animacija učitavanja, početni prikaz.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text("U izradi.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
        }
    }
}

// MARK: - Dizajn Islanda (vlastite postavke izgleda Islanda)
private struct DesignIslandSettingsSection: View {
    @AppStorage("themeRegistrySelectedThemeId") private var islandThemeId: String = "default"
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Dizajn Islanda")
                .font(.title.bold())
                .foregroundColor(accentColor)
            Text("Postavke izgleda samo za Island – neovisno o ostalim postavkama.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            SettingsCard(title: "Tema Islanda") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set ikona i stil za sadržaj u Islandu.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Picker("Tema", selection: $islandThemeId) {
                        ForEach(ThemeRegistry.all) { theme in
                            Text(theme.displayName).tag(theme.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: islandThemeId) { _, newValue in
                        ThemeRegistry.selectedThemeId = newValue
                    }
                }
            }
            SettingsCard(title: "Raspored i veličina") {
                Text("Raspored elemenata u Islandu, veličina panela – u izradi.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Dizajn tabova (vlastite postavke izgleda tabova)
private struct DesignTabsSettingsSection: View {
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Dizajn tabova")
                .font(.title.bold())
                .foregroundColor(accentColor)
            Text("Postavke izgleda samo za tabove i traku – neovisno o ostalim postavkama.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            SettingsCard(title: "Stil tabova") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Oblik, veličina, ikone i oznake na tabovima.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text("U izradi.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            SettingsCard(title: "Traka tabova") {
                Text("Visina trake, pozicija, grupe tabova – u izradi.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Dizajn: Teme (sustav light/dark + lista objekata s pretraživačem, Primjeni, Izbriši)
private struct DesignThemesSettingsSection: View {
    @AppStorage("appTheme") private var appThemeRaw = AppTheme.system.rawValue
    @AppStorage("themeRegistrySelectedThemeId") private var selectedThemeId: String = "default"
    @State private var themeSearchQuery: String = ""
    @ObservedObject private var catalogService = BackendCatalogService.shared
    let accentColor: Color

    private var appTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue; AppSettings.appTheme = $0 }
        )
    }

    /// Lista tema filtrirana po pretraživaču (naziv, opis).
    private var filteredThemes: [Theme] {
        let list = ThemeRegistry.themesForSelection
        let q = themeSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return list }
        return list.filter {
            $0.displayName.lowercased().contains(q) || $0.summary.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Teme")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Tema aplikacije") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { appTheme.wrappedValue == .system },
                        set: { appTheme.wrappedValue = $0 ? .system : .dark }
                    )) {
                        Text("Poveži sa sustavom")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .toggleStyle(.switch)
                    .tint(accentColor)
                    if appTheme.wrappedValue != .system {
                        HStack(spacing: 12) {
                            Button {
                                appTheme.wrappedValue = .light
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sun.max.fill")
                                    Text("Svijetla")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(appTheme.wrappedValue == .light ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.wrappedValue == .light ? accentColor.opacity(0.3) : Color.white.opacity(0.06)))
                            }
                            .buttonStyle(.plain)
                            Button {
                                appTheme.wrappedValue = .dark
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "moon.fill")
                                    Text("Tamna")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(appTheme.wrappedValue == .dark ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(appTheme.wrappedValue == .dark ? accentColor.opacity(0.3) : Color.white.opacity(0.06)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            SettingsCard(title: "Traži teme") {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    TextField("Traži teme…", text: $themeSearchQuery)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
            }

            SettingsCard(title: "Teme") {
                VStack(alignment: .leading, spacing: 12) {

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredThemes) { theme in
                                ThemeCardView(
                                    theme: theme,
                                    isSelected: selectedThemeId == theme.id,
                                    accentColor: accentColor,
                                    onApply: {
                                        selectedThemeId = theme.id
                                        ThemeRegistry.selectedThemeId = theme.id
                                    },
                                    onDelete: theme.id == "default" ? nil : {
                                        if selectedThemeId == theme.id {
                                            selectedThemeId = "default"
                                            ThemeRegistry.selectedThemeId = "default"
                                        }
                                        BackendCatalogService.shared.removeTheme(id: theme.id)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 420)

                    if filteredThemes.isEmpty {
                        Text("Nema tema za prikaz. Očisti filter ili preuzmi teme u Market → Teme.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    } else if ThemeRegistry.themesForSelection.count == 1 {
                        Text("Nema instaliranih tema. Idi u Market → Teme i preuzmi Classic ili drugu temu.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }
}

// MARK: - Objekt teme: minijatura = doslovna kopija UX-a (MainWindowPreviewView iz ContentView), Primjeni, Izbriši
private struct ThemeCardView: View {
    let theme: Theme
    let isSelected: Bool
    let accentColor: Color
    let onApply: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                MainWindowPreviewView(theme: theme)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(6)
                    .frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)

            Text(theme.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Button("Primjeni") {
                onApply()
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(accentColor)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let onDelete = onDelete {
                Button("Izbriši") {
                    onDelete()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.red.opacity(0.9))
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }
}

// MARK: - Dev Tools prikaz – redoslijed i uključivanje sekcija (General uvijek prvi i neuklonjiv)
private struct DevToolsDisplaySettingsSection: View {
    @ObservedObject private var sectionOrder = DevToolsSectionOrder.shared
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Dev Tools prikaz")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Redoslijed sekcija") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("General je uvijek prvi i ne može se maknuti. Ostale sekcije možeš uključiti/isključiti i promijeniti redoslijed.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    List {
                        ForEach(Array(sectionOrder.orderedSections.enumerated()), id: \.element.rawValue) { index, section in
                            HStack(spacing: 12) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(accentColor)
                                    .frame(width: 24, alignment: .center)
                                Text(section.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                if section != .general {
                                    Toggle("", isOn: Binding(
                                        get: { sectionOrder.isEnabled(section) },
                                        set: { _ in sectionOrder.toggleEnabled(section) }
                                    ))
                                    .labelsHidden()
                                } else {
                                    Text("uvijek uključeno")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onMove(perform: moveSections)
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 220)
                }
            }
        }
    }

    private func moveSections(from source: IndexSet, to destination: Int) {
        sectionOrder.move(from: source, to: destination)
    }
}

// MARK: - Swift (verzija i biblioteke)
private struct SwiftSettingsSection: View {
    let accentColor: Color

    private static let swiftDSLVersion = "1.0"
    private static let basicLibs = [
        "VStack, HStack, ZStack", "ScrollView, List, Form", "Text, Button, Image", "TextField, Toggle, Slider",
        "Spacer, Divider", "Padding, Frame", "Color, Shape", "TabView, GroupBox", "Label, Link"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Swift")
                .font(.title.bold())
                .foregroundColor(accentColor)

            SettingsCard(title: "Verzija") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(accentColor)
                        Text("Alexandria DSL")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("verzija \(Self.swiftDSLVersion)")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Text("Swift-podoban DSL za UI aplikacije na platformi. Parsira se i renderira u aplikaciji.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            SettingsCard(title: "Osnovne biblioteke") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dolaze s aplikacijom – dostupne u svakom appu bez dodatnog slanja.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Self.basicLibs, id: \.self) { lib in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(accentColor)
                                Text(lib)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                }
            }

            SettingsCard(title: "Specijalne biblioteke") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Specijalne libove moraš poslati zajedno s appom – uključi ih u zip paket (npr. dodatni .swift filei). Bez njih u paketu app ih ne može učitati.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)
                        Text("Paket (zip) mora sadržavati main datoteku i sve uključene/specijalne datoteke.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - Preuzimanja
private struct DownloadsSettingsSection: View {
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preuzimanja")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Preuzete datoteke") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mapa za preuzimanja, povijest, upozorenja pri otvaranju.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text("U izradi.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
        }
    }
}

// MARK: - Status spajanja
private struct ConnectionStatusSettingsSection: View {
    @AppStorage("isInternetEnabled") private var isInternetEnabled = true
    @ObservedObject private var networkMonitor = NetworkMonitorService.shared
    let accentColor: Color

    private var statusColor: Color {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Status spajanja")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Mreža") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Dozvoli spajanje na internet", isOn: $isInternetEnabled)
                        .toggleStyle(.switch)
                        .foregroundColor(.white)
                    HStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 24))
                            .foregroundColor(statusColor)
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

            SettingsCard(title: "Alexandria backend") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Za teme, jezike i plug-ine. Ako je prazno, koristi se Server kataloga (Pretraga aplikacija).")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 8) {
                        TextField("URL backenda (opcionalno)", text: Binding(
                            get: { AppSettings.alexandriaBackendBaseURL },
                            set: { AppSettings.alexandriaBackendBaseURL = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                    }
                    Toggle("Osvježi katalog pri pokretanju", isOn: Binding(
                        get: { AppSettings.syncCatalogOnLaunch },
                        set: { AppSettings.syncCatalogOnLaunch = $0 }
                    ))
                    .toggleStyle(.switch)
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Plaćanje i korisnički računi
private struct PaymentAndAccountsSettingsSection: View {
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Plaćanje i korisnički računi")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Račun i plaćanja") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Načini plaćanja, pretplate i podaci korisničkog računa.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text("U izradi.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
        }
    }
}

// MARK: - Status ugrađene aplikacije (boja + blinkanje)
private enum BuiltInAppStatus: String, CaseIterable {
    case off
    case operational  // zeleno
    case standby      // žuto
    case problem      // crveno blinkanje
    case standbyBlinking // žuto blinkanje

    var color: Color {
        switch self {
        case .off: return .red
        case .operational: return Color(hex: "22c55e")
        case .standby: return Color(hex: "eab308")
        case .problem: return .red
        case .standbyBlinking: return Color(hex: "eab308")
        }
    }

    var shouldBlink: Bool {
        switch self {
        case .problem, .standbyBlinking: return true
        default: return false
        }
    }
}

private func builtInAppEnabledKey(_ appId: String) -> String { "builtInApp.\(appId).enabled" }
private func builtInAppStatusKey(_ appId: String) -> String { "builtInApp.\(appId).status" }

// MARK: - Interval hvatanja prometa (Network data traffic)
private struct NetworkTrafficCaptureInterval: Identifiable, CaseIterable, Hashable {
    let id: Int
    let seconds: Int
    let label: String
    static let oneSec = NetworkTrafficCaptureInterval(id: 1, seconds: 1, label: "1 s")
    static let fiveSec = NetworkTrafficCaptureInterval(id: 5, seconds: 5, label: "5 s")
    static let thirtySec = NetworkTrafficCaptureInterval(id: 30, seconds: 30, label: "30 s")
    static let oneMin = NetworkTrafficCaptureInterval(id: 60, seconds: 60, label: "1 min")
    static let threeMin = NetworkTrafficCaptureInterval(id: 180, seconds: 180, label: "3 min")
    static let fiveMin = NetworkTrafficCaptureInterval(id: 300, seconds: 300, label: "5 min")
    static let tenMin = NetworkTrafficCaptureInterval(id: 600, seconds: 600, label: "10 min")
    static let fifteenMin = NetworkTrafficCaptureInterval(id: 900, seconds: 900, label: "15 min")
    static let thirtyMin = NetworkTrafficCaptureInterval(id: 1800, seconds: 1800, label: "30 min")
    static let fortyFiveMin = NetworkTrafficCaptureInterval(id: 2700, seconds: 2700, label: "45 min")
    static let sixtyMin = NetworkTrafficCaptureInterval(id: 3600, seconds: 3600, label: "60 min")
    static let twoHours = NetworkTrafficCaptureInterval(id: 7200, seconds: 7200, label: "120 min")
    static var allCases: [NetworkTrafficCaptureInterval] {
        [.oneSec, .fiveSec, .thirtySec, .oneMin, .threeMin, .fiveMin, .tenMin, .fifteenMin, .thirtyMin, .fortyFiveMin, .sixtyMin, .twoHours]
    }
    static func from(seconds: Int) -> NetworkTrafficCaptureInterval {
        allCases.first { $0.seconds == seconds } ?? .thirtySec
    }
}

private let kNetworkTrafficIntervalKey = "networkTraffic.intervalSeconds"
private let kNetworkTrafficSaveToFileKey = "networkTraffic.saveToFileEnabled"
private let kNetworkTrafficSavePathKey = "networkTraffic.saveToFilePath"

// MARK: - Jedan zapis hvatanog prometa (protokol, IP, portovi, veličina, tip, pokušaji, …)
private struct NetworkTrafficEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let protocolName: String
    let sourceIP: String
    let destIP: String
    let sourcePort: Int?
    let destPort: Int?
    let tabId: String?
    let info: String
    /// Veličina paketa / odgovora u bajtovima (nil = nije poznato, npr. ARP).
    let packetSize: Int?
    /// Tip sadržaja / datoteke (npr. "application/json", "text/html", "image/png").
    let contentType: String?
    /// Broj pokušaja (retry); 1 = prvi pokušaj.
    let attempts: Int?
    /// HTTP status (200, 404, 500) ili nil.
    let statusCode: Int?
    /// HTTP metoda (GET, POST, …) ili nil.
    let method: String?

    static var placeholder: [NetworkTrafficEntry] {
        [
            NetworkTrafficEntry(id: UUID(), timestamp: Date(), protocolName: "TCP", sourceIP: "192.168.1.10", destIP: "93.184.216.34", sourcePort: 52341, destPort: 443, tabId: "tab1", info: "api.example.com", packetSize: 1250, contentType: "application/json", attempts: 1, statusCode: 200, method: "GET"),
            NetworkTrafficEntry(id: UUID(), timestamp: Date().addingTimeInterval(-2), protocolName: "UDP", sourceIP: "192.168.1.10", destIP: "8.8.8.8", sourcePort: 54321, destPort: 53, tabId: nil, info: "DNS", packetSize: 64, contentType: nil, attempts: 1, statusCode: nil, method: nil),
            NetworkTrafficEntry(id: UUID(), timestamp: Date().addingTimeInterval(-5), protocolName: "ARP", sourceIP: "192.168.1.1", destIP: "192.168.1.10", sourcePort: nil, destPort: nil, tabId: nil, info: "Who has 192.168.1.10", packetSize: 42, contentType: nil, attempts: 1, statusCode: nil, method: nil),
            NetworkTrafficEntry(id: UUID(), timestamp: Date().addingTimeInterval(-8), protocolName: "TCP", sourceIP: "192.168.1.10", destIP: "151.101.1.69", sourcePort: 50102, destPort: 443, tabId: "tab1", info: "cdn.example.com", packetSize: 48_200, contentType: "image/png", attempts: 2, statusCode: 200, method: "GET"),
        ]
    }

    /// Veličina za prikaz (B, KB, MB).
    var packetSizeDisplay: String {
        guard let s = packetSize else { return "–" }
        if s < 1024 { return "\(s) B" }
        if s < 1024 * 1024 { return String(format: "%.1f KB", Double(s) / 1024) }
        return String(format: "%.1f MB", Double(s) / (1024 * 1024))
    }
}

private enum NetworkTrafficVizMode: String, CaseIterable {
    case general = "Opčenito"
    case perTab = "Po tabovima"
}

// MARK: - Network data traffic – jedan red (pretraga, interval, spremi) + vizualizacija ispod
private struct NetworkTrafficSettingsSection: View {
    let accentColor: Color

    @State private var isAppEnabled: Bool = false
    @AppStorage(kNetworkTrafficIntervalKey) private var intervalSeconds: Int = 30
    @AppStorage(kNetworkTrafficSaveToFileKey) private var saveToFileEnabled: Bool = false
    @AppStorage(kNetworkTrafficSavePathKey) private var saveToFilePath: String = ""
    @State private var searchQuery: String = ""
    @State private var vizMode: NetworkTrafficVizMode = .general
    @State private var trafficEntries: [NetworkTrafficEntry] = NetworkTrafficEntry.placeholder

    private var selectedInterval: Binding<NetworkTrafficCaptureInterval> {
        Binding(
            get: { NetworkTrafficCaptureInterval.from(seconds: intervalSeconds) },
            set: { intervalSeconds = $0.seconds }
        )
    }

    private var filteredEntries: [NetworkTrafficEntry] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return trafficEntries }
        return trafficEntries.filter {
            $0.sourceIP.lowercased().contains(q) ||
            $0.destIP.lowercased().contains(q) ||
            $0.protocolName.lowercased().contains(q) ||
            $0.info.lowercased().contains(q) ||
            ($0.contentType?.lowercased().contains(q) ?? false) ||
            ($0.method?.lowercased().contains(q) ?? false) ||
            ($0.sourcePort.map { "\($0)" }.map { $0.contains(q) } ?? false) ||
            ($0.destPort.map { "\($0)" }.map { $0.contains(q) } ?? false) ||
            ($0.packetSize.map { "\($0)" }.map { $0.contains(q) } ?? false) ||
            ($0.statusCode.map { "\($0)" }.map { $0.contains(q) } ?? false)
        }
    }

    private var groupedByTab: [(tabId: String, entries: [NetworkTrafficEntry])] {
        let withTab = filteredEntries.filter { $0.tabId != nil }
        let dict = Dictionary(grouping: withTab, by: { $0.tabId ?? "" })
        return dict.map { (tabId: $0.key, entries: $0.value) }.sorted { $0.tabId < $1.tabId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Network data traffic")
                .font(.title.bold())
                .foregroundColor(accentColor)

            if !isAppEnabled {
                SettingsCard(title: "Ugašeno") {
                    Text("Uključi „Network data traffic” u kratici postavki (Ugrađene aplikacije) da hvataš promet.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                // Jedan horizontalni red: pretraga | interval | spremi u datoteku
                HStack(alignment: .top, spacing: 16) {
                    SettingsCard(title: "Pretraga") {
                        TextField("URL, domena, host, IP, port…", text: $searchQuery)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)

                    SettingsCard(title: "Interval") {
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: selectedInterval) {
                                ForEach(NetworkTrafficCaptureInterval.allCases) { interval in
                                    Text(interval.label).tag(interval)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }
                    .frame(width: 140)

                    SettingsCard(title: "Spremi u datoteku") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Stream u datoteku", isOn: $saveToFileEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                            if saveToFileEnabled {
                                HStack(spacing: 6) {
                                    TextField("Put", text: $saveToFilePath)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 11))
                                    Button("Odaberi…", action: chooseSaveFile)
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Vizualizacija prometa: Opčenito / Po tabovima + tablica
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text("Vizualizacija prometa")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accentColor)
                        Picker("", selection: $vizMode) {
                            ForEach(NetworkTrafficVizMode.allCases, id: \.rawValue) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }

                    trafficTableCard
                }
            }
        }
        .onAppear {
            isAppEnabled = UserDefaults.standard.bool(forKey: builtInAppEnabledKey("networkTraffic"))
        }
    }

    private var trafficTableCard: some View {
        Group {
            if vizMode == .general {
                trafficTable(entries: filteredEntries)
            } else {
                if groupedByTab.isEmpty {
                    Text("Nema prometa po tabovima.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(24)
                } else {
                    ForEach(groupedByTab, id: \.tabId) { group in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tab: \(group.tabId)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            trafficTable(entries: group.entries)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    private func trafficTable(entries: [NetworkTrafficEntry]) -> some View {
        let columns = ["Vrijeme", "Protokol", "Izvor IP", "Odredište IP", "Izvor port", "Odredište port", "Veličina", "Tip", "Pokušaji", "Status", "Metoda", "Info"]
        let totalWidth: CGFloat = 72 + 56 + 110 + 110 + 72 + 72 + 72 + 100 + 56 + 52 + 48 + 140
        return ScrollView(.vertical, showsIndicators: true) {
            ScrollView(.horizontal, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    ForEach(columns, id: \.self) { col in
                        Text(col)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: colWidth(col), alignment: .leading)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.08))

                Divider().background(Color.white.opacity(0.15))

                if entries.isEmpty {
                    Text("Nema zapisa (filtrirani promet ili hvatanje nije pokrenuto).")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(16)
                } else {
                    ForEach(entries) { e in
                        HStack(spacing: 12) {
                            Text(shortTime(e.timestamp))
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(width: colWidth("Vrijeme"), alignment: .leading)
                            Text(e.protocolName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(accentColor)
                                .frame(width: colWidth("Protokol"), alignment: .leading)
                            Text(e.sourceIP)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(width: colWidth("Izvor IP"), alignment: .leading)
                            Text(e.destIP)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(width: colWidth("Odredište IP"), alignment: .leading)
                            Text(e.sourcePort.map { "\($0)" } ?? "–")
                                .font(.system(size: 11))
                                .frame(width: colWidth("Izvor port"), alignment: .leading)
                            Text(e.destPort.map { "\($0)" } ?? "–")
                                .font(.system(size: 11))
                                .frame(width: colWidth("Odredište port"), alignment: .leading)
                            Text(e.packetSizeDisplay)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                                .frame(width: colWidth("Veličina"), alignment: .leading)
                            Text(e.contentType ?? "–")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: colWidth("Tip"), alignment: .leading)
                            Text(e.attempts.map { "\($0)" } ?? "–")
                                .font(.system(size: 11))
                                .frame(width: colWidth("Pokušaji"), alignment: .leading)
                            Text(e.statusCode.map { "\($0)" } ?? "–")
                                .font(.system(size: 11))
                                .foregroundColor(e.statusCode.map { $0 >= 400 ? .orange : .white } ?? .white)
                                .frame(width: colWidth("Status"), alignment: .leading)
                            Text(e.method ?? "–")
                                .font(.system(size: 11))
                                .frame(width: colWidth("Metoda"), alignment: .leading)
                            Text(e.info)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(minWidth: 120, alignment: .leading)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                    }
                }
                }
                .frame(minWidth: totalWidth)
            }
        }
    }

    private func colWidth(_ name: String) -> CGFloat {
        switch name {
        case "Vrijeme": return 72
        case "Protokol": return 56
        case "Izvor IP", "Odredište IP": return 110
        case "Izvor port", "Odredište port": return 72
        case "Veličina": return 72
        case "Tip": return 100
        case "Pokušaji": return 56
        case "Status": return 52
        case "Metoda": return 48
        default: return 100
        }
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: date)
    }

    private func chooseSaveFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText, .data]
        panel.nameFieldStringValue = "network-traffic-\(ISO8601DateFormatter().string(from: Date()).prefix(19).replacingOccurrences(of: ":", with: "-")).log"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                saveToFilePath = url.path
            }
        }
    }
}

// MARK: - Okrugli gumb uključi/isključi u kratici (sidebar) – zeleno/žuto/crveno, blinkanje
private struct BuiltInAppStatusButtonView: View {
    let appId: String

    @State private var isEnabled: Bool = false
    @State private var currentStatus: BuiltInAppStatus = .off
    @State private var blinkOpacity: CGFloat = 1
    @State private var blinkTimer: Timer?

    private var displayStatus: BuiltInAppStatus {
        isEnabled ? currentStatus : .off
    }

    var body: some View {
        Button {
            if isEnabled {
                isEnabled = false
                currentStatus = .off
                blinkTimer?.invalidate()
                blinkOpacity = 1
            } else {
                isEnabled = true
                currentStatus = .operational
            }
            UserDefaults.standard.set(isEnabled, forKey: builtInAppEnabledKey(appId))
            UserDefaults.standard.set(currentStatus.rawValue, forKey: builtInAppStatusKey(appId))
        } label: {
            Circle()
                .fill(displayStatus.color.opacity(displayStatus.shouldBlink ? blinkOpacity : 1))
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onAppear {
            isEnabled = UserDefaults.standard.bool(forKey: builtInAppEnabledKey(appId))
            if let raw = UserDefaults.standard.string(forKey: builtInAppStatusKey(appId)),
               let s = BuiltInAppStatus(rawValue: raw) {
                currentStatus = s
            } else {
                currentStatus = isEnabled ? .operational : .off
            }
            if isEnabled && currentStatus.shouldBlink { startBlinking() }
        }
        .onDisappear { blinkTimer?.invalidate() }
        .onChange(of: displayStatus.shouldBlink) { _, shouldBlink in
            if shouldBlink { startBlinking() } else { blinkTimer?.invalidate(); blinkOpacity = 1 }
        }
    }

    private func startBlinking() {
        blinkTimer?.invalidate()
        blinkOpacity = 1
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    blinkOpacity = blinkOpacity > 0.5 ? 0.35 : 1
                }
            }
        }
        RunLoop.main.add(blinkTimer!, forMode: .common)
    }
}

// MARK: - Ugrađena aplikacija (VPN, Security agent, Network traffic, Dev tools) – tab sadržaj, bez gumba (gumb je u kratici)
private struct BuiltInAppSettingsSection: View {
    let appId: String
    let title: String
    let icon: String
    let subtitle: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: title) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                        .frame(width: 28, alignment: .center)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("U izradi.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - Postavke tabova (pri pokretanju, novi tab)
private struct TabsSettingsSection: View {
    @AppStorage("onOpenAction") private var onOpenActionRaw = OnOpenAction.search.rawValue
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Postavke tabova")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Pri pokretanju i novi tab") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Što se otvori kad se pokrene aplikacija i kad stisneš „Novi tab”.")
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

// MARK: - Modovi rada (ikone: kuća, aktovka, štit, odmor, offline…; dodaj / ukloni / preimenuj)
private struct WorkModesSettingsSection: View {
    @ObservedObject var workModeStorage = WorkModeStorage.shared
    let accentColor: Color
    @State private var newModeName = ""
    @State private var newModeIconPresetId: String = "home"
    @State private var showAddMode = false
    @State private var renamingModeId: String?
    @State private var renameText = ""
    /// Kad je postavljen, prikaže se prozor „što mod donosi” za taj mod.
    @State private var presentedModeIdForDetails: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Modovi")
                .font(.title.bold())
                .foregroundColor(accentColor)

            Text("Modovi mogu imati različitu temu, dopuštenja, sigurnost i raspored ikona na Islandu. Svakom modu dodijeli ikonu (kuća, posao, sigurnost, odmor, offline…).")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            SettingsCard(title: "Modovi") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(workModeStorage.workModes) { mode in
                        HStack(spacing: 12) {
                            if renamingModeId == mode.id {
                                TextField("Naziv", text: $renameText)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit { submitRename(modeId: mode.id) }
                                Button("Spremi") { submitRename(modeId: mode.id) }
                                    .buttonStyle(.borderedProminent)
                                Button("Odustani") { renamingModeId = nil }
                                    .buttonStyle(.bordered)
                            } else {
                                Image(systemName: mode.iconSymbolName)
                                    .font(.system(size: 20))
                                    .foregroundColor(accentColor)
                                    .frame(width: 28, alignment: .center)
                                Text(mode.displayName)
                                    .font(.system(size: 14))
                                Spacer()
                                Toggle("Prikaži", isOn: Binding(
                                    get: { presentedModeIdForDetails == mode.id },
                                    set: { if $0 { presentedModeIdForDetails = mode.id } else { presentedModeIdForDetails = nil } }
                                ))
                                .toggleStyle(.switch)
                                .labelsHidden()
                                Menu {
                                    ForEach(ModeIconPreset.all) { preset in
                                        Button {
                                            workModeStorage.setModeIcon(id: mode.id, iconName: preset.symbolName)
                                        } label: {
                                            Label(preset.displayName, systemImage: preset.symbolName)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "circle.grid.2x2")
                                        .font(.system(size: 14))
                                        .foregroundColor(accentColor)
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                                Button("Preimenuj") {
                                    renameText = mode.displayName
                                    renamingModeId = mode.id
                                }
                                .buttonStyle(.bordered)
                                if !mode.isBuiltIn {
                                    Button(role: .destructive) {
                                        workModeStorage.removeMode(id: mode.id)
                                    } label: { Image(systemName: "trash") }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Button("Dodaj mod") {
                        newModeName = ""
                        newModeIconPresetId = "home"
                        showAddMode = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            SettingsCard(title: "Pri pokretanju") {
                Toggle("Uvijek pitaj koji mod pri pokretanju", isOn: Binding(
                    get: { WorkModeStorage.showPickerOnLaunch },
                    set: { WorkModeStorage.showPickerOnLaunch = $0 }
                ))
                .toggleStyle(.switch)
                Text("Ako je uključeno, pri svakom pokretanju aplikacije možeš odabrati mod. Inače se koristi zadnji odabrani mod.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .sheet(isPresented: $showAddMode) {
            addModeSheet
        }
        .sheet(isPresented: Binding(
            get: { presentedModeIdForDetails != nil },
            set: { if !$0 { presentedModeIdForDetails = nil } }
        )) {
            Group {
                if let modeId = presentedModeIdForDetails, let mode = workModeStorage.mode(for: modeId) {
                    ModeDetailsSheetView(mode: mode, accentColor: accentColor) {
                        presentedModeIdForDetails = nil
                    }
                } else {
                    VStack {
                        Text("Mod nije pronađen")
                        Button("Zatvori") { presentedModeIdForDetails = nil }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }

    private var addModeSheet: some View {
        let selectedPreset = ModeIconPreset.all.first { $0.id == newModeIconPresetId } ?? ModeIconPreset.all[0]
        return VStack(spacing: 20) {
            Text("Novi mod")
                .font(.headline)
            TextField("Naziv moda", text: $newModeName)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 220)
            Text("Ikona moda")
                .font(.subheadline.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                ForEach(ModeIconPreset.all) { preset in
                    Button {
                        newModeIconPresetId = preset.id
                    } label: {
                        Image(systemName: preset.symbolName)
                            .font(.system(size: 22))
                            .foregroundColor(newModeIconPresetId == preset.id ? accentColor : .white.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(newModeIconPresetId == preset.id ? accentColor.opacity(0.2) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxHeight: 200)
            HStack {
                Button("Odustani") { showAddMode = false }
                Button("Dodaj") {
                    let name = newModeName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        workModeStorage.addMode(displayName: name, iconName: selectedPreset.symbolName)
                        showAddMode = false
                    }
                }
                .disabled(newModeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360, height: 380)
    }

    private func submitRename(modeId: String) {
        let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            workModeStorage.renameMode(id: modeId, displayName: name)
        }
        renamingModeId = nil
    }
}

// MARK: - Prozor „što mod donosi” – tema, dopuštenja, sigurnost, raspored Islanda itd.
private struct ModeDetailsSheetView: View {
    let mode: WorkMode
    let accentColor: Color
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: mode.iconSymbolName)
                    .font(.system(size: 28))
                    .foregroundColor(accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Što ovaj mod donosi")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button("Zatvori") { onDismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(Color.white.opacity(0.05))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailRow(icon: "paintbrush.fill", title: "Tema", summary: "Izgled aplikacije – boje, fontovi, pozadina – posebno za ovaj mod.")
                    detailRow(icon: "lock.shield.fill", title: "Sigurnost", summary: "Postavke sigurnosti i zaštite po modu (npr. pojačana za mod Sigurnost).")
                    detailRow(icon: "hand.raised.fill", title: "Dopuštenja", summary: "Što aplikacija smije u ovom modu – mreža, lokacija, pristup datotekama.")
                    detailRow(icon: "capsule", title: "Raspored Islanda", summary: "Redoslijed i izbor ikona u Fazi 1 i Fazi 2 – uređuje se u Postavkama Islanda za ovaj mod.")
                    detailRow(icon: "square.grid.2x2", title: "Widgeti i kratice", summary: "Mod može imati posebne widgete ili kratice (u izradi).")
                }
                .padding(24)
            }
        }
        .frame(minWidth: 420, minHeight: 400)
    }

    private func detailRow(icon: String, title: String, summary: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(accentColor)
                .frame(width: 32, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }
}

// MARK: - Postavke Islanda (natpis, search panel, mod rada, Faza 1 & 2 ikone)
private struct IslandSettingsSection: View {
    @Binding var searchPanelPositionRaw: String
    @ObservedObject var workModeStorage = WorkModeStorage.shared
    let accentColor: Color

    @State private var editingModeId: String = WorkModeStorage.currentModeId
    @State private var phase1Keys: [IslandIconKey] = []
    @State private var phase2Keys: [IslandIconKey] = []

    private func loadOrders() {
        phase1Keys = IslandLayoutStorage.phase1Order(modeId: editingModeId)
        phase2Keys = IslandLayoutStorage.phase2Order(modeId: editingModeId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Postavke Islanda")
                .font(.title.bold())
                .foregroundColor(accentColor)
            SettingsCard(title: "Search panel") {
                Picker("Pozicija", selection: $searchPanelPositionRaw) {
                    ForEach(SearchPanelPosition.allCases, id: \.rawValue) { position in
                        Text(position.label).tag(position.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Aktivni mod – koji set ikona Island trenutno prikazuje u aplikaciji.
            SettingsCard(title: "Aktivni mod") {
                Picker("", selection: Binding(
                    get: { WorkModeStorage.currentModeId },
                    set: { workModeStorage.setCurrentMode(id: $0) }
                )) {
                    ForEach(workModeStorage.workModes) { mode in
                        Label(mode.displayName, systemImage: mode.iconSymbolName).tag(mode.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Mod rada za uređivanje – ikone ispod vrijede za ovaj mod (može biti drugačiji od aktivnog).
            SettingsCard(title: "Uredi ikone za mod") {
                Picker("", selection: $editingModeId) {
                    ForEach(workModeStorage.workModes) { mode in
                        Label(mode.displayName, systemImage: mode.iconSymbolName).tag(mode.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .onChange(of: editingModeId) { _, _ in loadOrders() }
            }

            // Island uvećan na ekranu: Faza 1 (blizu), ispod Faza 2 (potpuno otvoreno) – obje s drag and drop.
            SettingsCard(title: "Raspored Islanda – povuci ikone za redoslijed") {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Uvećani prikaz Islanda. Povuci ikone na željeno mjesto u obje faze.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    // Faza 1 – kad dođeš blizu (uvećana na ekranu)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Faza 1 – kad dođeš blizu")
                            .font(.subheadline.bold())
                            .foregroundColor(accentColor)
                        IslandPhase1ReorderPreview(
                            keys: $phase1Keys,
                            accentColor: accentColor,
                            onReorder: { IslandLayoutStorage.setPhase1Order(modeId: editingModeId, keys: phase1Keys) }
                        )
                    }

                    // Faza 2 – potpuno otvoreno (uvećana ispod)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Faza 2 – potpuno otvoreno")
                            .font(.subheadline.bold())
                            .foregroundColor(accentColor)
                        IslandPhase2ReorderPreview(
                            keys: $phase2Keys,
                            accentColor: accentColor,
                            onReorder: { IslandLayoutStorage.setPhase2Order(modeId: editingModeId, keys: phase2Keys) }
                        )
                    }

                    Divider()
                        .background(accentColor.opacity(0.5))

                    // Zamjena ikona po slotu (liste) i Vrati na zadano
                    Text("Zamjena ikone po slotu")
                        .font(.subheadline.bold())
                        .foregroundColor(accentColor)
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Faza 1")
                                .font(.caption.bold())
                            List {
                                ForEach(phase1Keys.indices, id: \.self) { index in
                                    IslandIconRow(
                                        key: phase1Keys[index],
                                        accentColor: accentColor,
                                        selection: Binding(
                                            get: { phase1Keys[index] },
                                            set: { new in
                                                phase1Keys[index] = new
                                                IslandLayoutStorage.setPhase1Order(modeId: editingModeId, keys: phase1Keys)
                                            }
                                        )
                                    )
                                }
                                .onMove { from, to in
                                    phase1Keys.move(fromOffsets: from, toOffset: to)
                                    IslandLayoutStorage.setPhase1Order(modeId: editingModeId, keys: phase1Keys)
                                }
                            }
                            .listStyle(.plain)
                            .frame(minHeight: 120)
                            Button("Vrati Fazu 1 na zadano") {
                                phase1Keys = IslandLayoutStorage.defaultPhase1Order
                                IslandLayoutStorage.setPhase1Order(modeId: editingModeId, keys: phase1Keys)
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Faza 2")
                                .font(.caption.bold())
                            List {
                                ForEach(phase2Keys.indices, id: \.self) { index in
                                    IslandIconRow(
                                        key: phase2Keys[index],
                                        accentColor: accentColor,
                                        selection: Binding(
                                            get: { phase2Keys[index] },
                                            set: { new in
                                                phase2Keys[index] = new
                                                IslandLayoutStorage.setPhase2Order(modeId: editingModeId, keys: phase2Keys)
                                            }
                                        )
                                    )
                                }
                                .onMove { from, to in
                                    phase2Keys.move(fromOffsets: from, toOffset: to)
                                    IslandLayoutStorage.setPhase2Order(modeId: editingModeId, keys: phase2Keys)
                                }
                            }
                            .listStyle(.plain)
                            .frame(minHeight: 160)
                            Button("Vrati Fazu 2 na zadano") {
                                phase2Keys = IslandLayoutStorage.defaultPhase2Order
                                IslandLayoutStorage.setPhase2Order(modeId: editingModeId, keys: phase2Keys)
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            if !workModeStorage.workModes.contains(where: { $0.id == editingModeId }) {
                editingModeId = WorkModeStorage.currentModeId
            }
            loadOrders()
        }
    }
}

// MARK: - Uvećani Island Faza 1 – povuci i ispusti ikone za redoslijed
private struct IslandPhase1ReorderPreview: View {
    @Binding var keys: [IslandIconKey]
    let accentColor: Color
    var onReorder: () -> Void

    private let scale: CGFloat = 2.0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(keys.indices, id: \.self) { index in
                phase1Slot(key: keys[index], index: index)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(accentColor, lineWidth: 1))
        )
    }

    private func phase1Slot(key: IslandIconKey, index: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: IslandIcon.symbol(for: key))
                .font(.system(size: 10 * scale))
            Text(key.displayLabel)
                .font(.system(size: 8 * scale, weight: .medium))
        }
        .foregroundColor(accentColor)
        .frame(minWidth: 36 * scale * 0.6)
        .padding(.vertical, 6 * scale)
        .padding(.horizontal, 10 * scale)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .draggable("\(index):\(key.rawValue)")
        .dropDestination(for: String.self) { dropped, _ in
            let payload = dropped.first ?? ""
            let parts = payload.split(separator: ":", maxSplits: 1)
            let fromIdx = parts.first.flatMap { Int($0) } ?? 0
            guard fromIdx >= 0, fromIdx < keys.count else { return false }
            let k = keys[fromIdx]
            var newKeys = keys
            newKeys.remove(at: fromIdx)
            let toIdx = fromIdx < index ? index - 1 : index
            newKeys.insert(k, at: toIdx)
            keys = newKeys
            onReorder()
            return true
        }
    }
}

// MARK: - Uvećani Island Faza 2 – povuci i ispusti ikone za redoslijed
private struct IslandPhase2ReorderPreview: View {
    @Binding var keys: [IslandIconKey]
    let accentColor: Color
    var onReorder: () -> Void

    private let scale: CGFloat = 2.0

    var body: some View {
        HStack(spacing: 10) {
            ForEach(keys.indices, id: \.self) { index in
                phase2Slot(key: keys[index], index: index)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(accentColor, lineWidth: 1))
        )
    }

    private func phase2Slot(key: IslandIconKey, index: Int) -> some View {
        Image(systemName: IslandIcon.symbol(for: key))
            .font(.system(size: 11 * scale))
            .foregroundColor(accentColor)
            .frame(width: 26 * scale, height: 26 * scale)
            .background(Circle().fill(Color.white.opacity(0.08)))
            .draggable("\(index):\(key.rawValue)")
            .dropDestination(for: String.self) { dropped, _ in
                let payload = dropped.first ?? ""
                let parts = payload.split(separator: ":", maxSplits: 1)
                let fromIdx = parts.first.flatMap { Int($0) } ?? 0
                guard fromIdx >= 0, fromIdx < keys.count else { return false }
                let k = keys[fromIdx]
                var newKeys = keys
                newKeys.remove(at: fromIdx)
                let toIdx = fromIdx < index ? index - 1 : index
                newKeys.insert(k, at: toIdx)
                keys = newKeys
                onReorder()
                return true
            }
    }
}

// Jedan red u postavkama Islanda: ikona + natpis + Picker za zamjenu.
private struct IslandIconRow: View {
    let key: IslandIconKey
    let accentColor: Color
    @Binding var selection: IslandIconKey

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: IslandIcon.symbol(for: key))
                .font(.system(size: 14))
                .foregroundColor(accentColor)
                .frame(width: 24, alignment: .center)
            Text(key.displayLabel)
                .font(.system(size: 13))
                .foregroundColor(.white)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(IslandIconKey.allCases, id: \.self) { k in
                    Text(k.displayLabel).tag(k)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Prikaz avatara iz Data (krug) ili placeholder
private struct ProfileAvatarView: View {
    let imageData: Data?
    let accentColor: Color
    let size: CGFloat
    
    var body: some View {
        Group {
            if let data = imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(accentColor.opacity(0.8))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Jedno polje u formi (postavke)
private struct SettingsProfileField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
        }
    }
}

// MARK: - Općenito (samo profili – lista i Dodaj profil)
private struct GeneralSettingsSection: View {
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
        }
    }
}

// MARK: - Create new account (Moj profil: slika, podaci, osobe)
private struct CreateNewAccountSection: View {
    @ObservedObject var manager: ProfileManager
    let accentColor: Color
    
    @State private var editFirstName: String = ""
    @State private var editLastName: String = ""
    @State private var editMiddleName: String = ""
    @State private var editPreferredDisplayName: String = ""
    @State private var editEmail: String = ""
    @State private var editPhone: String = ""
    @State private var editAvatarImageData: Data?
    @State private var editPeople: [ProfilePerson] = []
    @State private var newPersonName: String = ""
    @State private var newPersonRelation: String = ""
    @State private var showImagePicker = false
    
    private var current: Profile? { manager.currentProfile }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Create new account")
                .font(.title.bold())
                .foregroundColor(accentColor)
            
            if let profile = current {
                SettingsCard(title: "Moj profil") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 16) {
                            ProfileAvatarView(imageData: editAvatarImageData, accentColor: accentColor, size: 72)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Slika profila")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Button("Odaberi sliku…") {
                                    showImagePicker = true
                                }
                                .font(.system(size: 12))
                                .foregroundColor(accentColor)
                                .buttonStyle(.plain)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        Text("Ime, prezime, naziv, email i mobitel – sve što je za moderni browser bitno.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        SettingsProfileField(label: "Ime", placeholder: "Ime", text: $editFirstName)
                        SettingsProfileField(label: "Prezime", placeholder: "Prezime", text: $editLastName)
                        SettingsProfileField(label: "Srednje ime", placeholder: "Opcionalno", text: $editMiddleName)
                        SettingsProfileField(label: "Naziv", placeholder: "Kako želite da se prikažete", text: $editPreferredDisplayName)
                        SettingsProfileField(label: "Email adresa", placeholder: "email@primjer.hr", text: $editEmail)
                        SettingsProfileField(label: "Mobitel", placeholder: "+385 9x xxx xxxx", text: $editPhone)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Osobe")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Dodajte članove obitelji ili kontakte povezane s ovim profilom.")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                            ForEach(editPeople) { person in
                                HStack(spacing: 8) {
                                    Text(person.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                    if let r = person.relation, !r.isEmpty {
                                        Text("(\(r))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    Spacer()
                                    Button {
                                        editPeople.removeAll { $0.id == person.id }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.red.opacity(0.9))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                            }
                            HStack(spacing: 8) {
                                TextField("Ime osobe", text: $newPersonName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                                TextField("Odnos (npr. Supruga)", text: $newPersonRelation)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .frame(maxWidth: 140)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                                Button("Dodaj") {
                                    let name = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !name.isEmpty else { return }
                                    editPeople.append(ProfilePerson(name: name, relation: newPersonRelation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newPersonRelation.trimmingCharacters(in: .whitespacesAndNewlines)))
                                    newPersonName = ""
                                    newPersonRelation = ""
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(accentColor))
                                .buttonStyle(.plain)
                                .disabled(newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Button("Spremi") {
                                saveProfile(profile)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(accentColor))
                            .buttonStyle(.plain)
                        }
                    }
                }
                .fileImporter(isPresented: $showImagePicker, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
                    guard case .success(let urls) = result, let url = urls.first else { return }
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        editAvatarImageData = resizedAvatarData(from: data, maxSize: 256)
                    }
                }
                .onAppear { syncFromProfile(profile) }
                .onChange(of: current?.id) { _, _ in
                    if let p = current { syncFromProfile(p) }
                }
            } else {
                SettingsCard(title: "Moj profil") {
                    Text("Nema aktivnog profila. U općenito dodajte profil ili odaberite „Koristi” uz jedan od profila.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private func syncFromProfile(_ profile: Profile) {
        editFirstName = profile.firstName ?? ""
        editLastName = profile.lastName ?? ""
        editMiddleName = profile.middleName ?? ""
        editPreferredDisplayName = profile.preferredDisplayName ?? ""
        editEmail = profile.email ?? ""
        editPhone = profile.phone ?? ""
        editAvatarImageData = profile.avatarImageData
        editPeople = profile.people ?? []
    }
    
    private func saveProfile(_ profile: Profile) {
        let updated = Profile(
            id: profile.id,
            name: profile.name,
            createdAt: profile.createdAt,
            firstName: editFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editFirstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: editLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editLastName.trimmingCharacters(in: .whitespacesAndNewlines),
            middleName: editMiddleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editMiddleName.trimmingCharacters(in: .whitespacesAndNewlines),
            preferredDisplayName: editPreferredDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editPreferredDisplayName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: editEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: editPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarImageData: editAvatarImageData,
            people: editPeople.isEmpty ? nil : editPeople
        )
        manager.updateProfile(updated)
    }
}

private func resizedAvatarData(from data: Data, maxSize: CGFloat) -> Data? {
    guard let nsImage = NSImage(data: data) else { return nil }
    let w = nsImage.size.width
    let h = nsImage.size.height
    guard w > 0, h > 0 else { return nil }
    let scale = min(maxSize / w, maxSize / h, 1)
    let newW = w * scale
    let newH = h * scale
    let newSize = NSSize(width: newW, height: newH)
    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    nsImage.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: nsImage.size), operation: .copy, fraction: 1)
    newImage.unlockFocus()
    return newImage.tiffRepresentation ?? newImage.pngData()
}

private extension NSImage {
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
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
    @AppStorage("themeRegistrySelectedThemeId") private var islandThemeId: String = "default"
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
            
            SettingsCard(title: "Tema Islanda") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ikone u Islandu – odaberi set ikona (kasnije i teme s marketa).")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Picker("Tema", selection: $islandThemeId) {
                        ForEach(ThemeRegistry.all) { theme in
                            Text(theme.displayName).tag(theme.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: islandThemeId) { _, newValue in
                        ThemeRegistry.selectedThemeId = newValue
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

// MARK: - Ograničenja i dozvole (veličina zipa, main datoteke, dubina parsera; posebna dozvola za prekoračenje)
private struct LimitsAndPermissionsSettingsSection: View {
    let accentColor: Color
    @State private var maxZipSizeMB: String = ""
    @State private var maxMainFileSizeMB: String = ""
    @State private var allowExceedSizeLimits: Bool = AppLimitsSettings.allowExceedSizeLimits
    @State private var parserMaxDepth: Int = AppLimitsSettings.parserMaxDepth

    private static let parserDepthMin = 10
    private static let parserDepthMax = 2000

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Ograničenja i dozvole")
                .font(.title.bold())
                .foregroundColor(accentColor)

            SettingsCard(title: "Veličina paketa i datoteka") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Opcionalni limiti. Prazno = bez limita. Za prekoračenje treba uključiti posebnu dozvolu dolje.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    HStack(alignment: .center, spacing: 12) {
                        Text("Max zip (MB)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .leading)
                        TextField("Bez limita", text: $maxZipSizeMB)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: maxZipSizeMB) { _, newValue in
                                if newValue.isEmpty {
                                    AppLimitsSettings.maxZipSizeBytes = nil
                                } else if let n = Int(newValue.filter { $0.isNumber }) {
                                    AppLimitsSettings.maxZipSizeBytes = n > 0 ? n * 1024 * 1024 : nil
                                }
                            }
                    }
                    HStack(alignment: .center, spacing: 12) {
                        Text("Max main datoteka (MB)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .leading)
                        TextField("Bez limita", text: $maxMainFileSizeMB)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: maxMainFileSizeMB) { _, newValue in
                                if newValue.isEmpty {
                                    AppLimitsSettings.maxMainFileSizeBytes = nil
                                } else if let n = Int(newValue.filter { $0.isNumber }) {
                                    AppLimitsSettings.maxMainFileSizeBytes = n > 0 ? n * 1024 * 1024 : nil
                                }
                            }
                    }
                }
            }

            SettingsCard(title: "Posebna dozvola") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Dopusti prekoračenje limita veličine", isOn: $allowExceedSizeLimits)
                        .toggleStyle(.switch)
                        .foregroundColor(.white)
                        .onChange(of: allowExceedSizeLimits) { _, v in
                            AppLimitsSettings.allowExceedSizeLimits = v
                        }
                    Text("Kad uključeno, instalacija i učitavanje appova mogu prekoračiti postavljeni limit zipa i main datoteke.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            SettingsCard(title: "Parser – dubina ugniježđenja") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Maksimalna dubina ugniježđenja (npr. VStack u VStack…). Raspon \(Self.parserDepthMin)–\(Self.parserDepthMax).")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 16) {
                        Stepper("Dubina: \(parserMaxDepth)", value: $parserMaxDepth, in: Self.parserDepthMin...Self.parserDepthMax)
                            .foregroundColor(.white)
                            .onChange(of: parserMaxDepth) { _, v in
                                AppLimitsSettings.parserMaxDepth = v
                            }
                        Text("\(parserMaxDepth)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentColor)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }

            SettingsCard(title: "Buduće opcije") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ovdje će se moći namjestiti: korištenje Neural Enginea, limit RAM-a, pristup memoriji i sl. (proširivo).")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .onAppear {
            if let b = AppLimitsSettings.maxZipSizeBytes, b > 0 {
                maxZipSizeMB = "\(b / 1024 / 1024)"
            } else {
                maxZipSizeMB = ""
            }
            if let b = AppLimitsSettings.maxMainFileSizeBytes, b > 0 {
                maxMainFileSizeMB = "\(b / 1024 / 1024)"
            } else {
                maxMainFileSizeMB = ""
            }
            allowExceedSizeLimits = AppLimitsSettings.allowExceedSizeLimits
            parserMaxDepth = AppLimitsSettings.parserMaxDepth
        }
    }
}

// MARK: - Sigurnost (password, FIDO2, device trust, session, permissions, sandbox, E2E, activity log, export/wipe)
private struct SecuritySettingsSection: View {
    let accentColor: Color
    @AppStorage("securitySandboxLevel") private var sandboxLevelRaw = SecuritySandboxLevel.normal.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Sigurnost")
                    .font(.title.bold())
                    .foregroundColor(accentColor)

                // 🔐 Autentifikacija: lozinka, FIDO2
                securityCard(
                    title: "🔐 Autentifikacija",
                    subtitle: "Lozinka, FIDO2 i višefaktorska autentifikacija.",
                    icon: "lock.shield.fill"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        securityRow("Lozinka", detail: "Glavna lozinka / promjena lozinke", status: "u izradi")
                        securityRow("FIDO2 / WebAuthn", detail: "Hardverski ključevi, Face ID, Touch ID", status: "u izradi")
                        securityRow("2FA", detail: "Dvofaktorska autentifikacija", status: "u izradi")
                    }
                }

                // 1️⃣ Device trust
                securityCard(
                    title: "1️⃣ Device trust",
                    subtitle: "Lista pouzdanih uređaja, opoziv po uređaju, istek sessiona po uređaju. Sprječava zloupotrebu računa.",
                    icon: "laptopcomputer.and.iphone"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("„Trusted device” lista, opoziv pojedinog uređaja, session expiry po uređaju.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("U izradi.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                // 2️⃣ Session kontrola
                securityCard(
                    title: "2️⃣ Session kontrola",
                    subtitle: "Max trajanje sessiona, auto logout kad je idle, prikaz aktivnih sessiona. Standard u ozbiljnim sustavima.",
                    icon: "clock.badge.checkmark"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Max trajanje sessiona, auto logout (idle), prikaz aktivnih sessiona.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("U izradi.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                // 3️⃣ Permission dashboard
                securityCard(
                    title: "3️⃣ Permission dashboard",
                    subtitle: "Koje app imaju pristup datotekama, mikrofonu, kameri, mreži – s mogućnošću opoziva. Transparentnost.",
                    icon: "list.bullet.rectangle"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pristup datotekama, mic/camera, mreža – revoke po aplikaciji.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("U izradi.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                // 4️⃣ App sandbox razine
                securityCard(
                    title: "4️⃣ App sandbox razine",
                    subtitle: "Strict, Normal, Developer mode – korisnik bira sigurnost vs fleksibilnost.",
                    icon: "square.stack.3d.up"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Profil", selection: $sandboxLevelRaw) {
                            ForEach(SecuritySandboxLevel.allCases, id: \.rawValue) { level in
                                Text(level.label).tag(level.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        Text("Strict = maksimalna izolacija, Normal = uravnoteženo, Developer = više pristupa za razvoj.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // 5️⃣ E2E enkripcija
                securityCard(
                    title: "5️⃣ E2E enkripcija",
                    subtitle: "Za dokumente, poruke i lokalne podatke. Privatnost.",
                    icon: "lock.rectangle.stack"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dokumenti, poruke, lokalni podatke – opcija end-to-end šifriranja.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("U izradi.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                // 6️⃣ Activity log
                securityCard(
                    title: "6️⃣ Activity log",
                    subtitle: "Login attempts, pristup podacima, promjene postavki. Rano otkrivanje problema.",
                    icon: "doc.text.magnifyingglass"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prijave, pristup podacima, promjene postavki.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                        Text("U izradi.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }

                // 7️⃣ Data export & wipe
                securityCard(
                    title: "7️⃣ Data export & wipe",
                    subtitle: "Export podataka i „wipe all data”. GDPR-friendly.",
                    icon: "square.and.arrow.up"
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                // export – u izradi
                            } label: {
                                Label("Export podataka", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(accentColor)
                            }
                            .buttonStyle(.plain)
                            Spacer()
                            Button(role: .destructive) {
                                // wipe – u izradi
                            } label: {
                                Label("Wipe all data", systemImage: "trash")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        Text("Export u formatu pogodnom za prijenos; wipe trajno briše sve lokalne podatke.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    private func securityCard<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        SettingsCard(title: title) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(accentColor)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                content()
            }
        }
    }

    private func securityRow(_ label: String, detail: String, status: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Text(status)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(accentColor)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
    }
}

// Razine sandboxa za sigurnosnu postavku
private enum SecuritySandboxLevel: String, CaseIterable {
    case strict = "strict"
    case normal = "normal"
    case developer = "developer"

    var label: String {
        switch self {
        case .strict: return "Strict"
        case .normal: return "Normal"
        case .developer: return "Developer"
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
