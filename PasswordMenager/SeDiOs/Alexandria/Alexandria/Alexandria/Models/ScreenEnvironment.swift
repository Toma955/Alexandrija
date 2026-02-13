//
//  ScreenEnvironment.swift
//  Alexandria
//
//  Reaktivno okruženje ekrana za webapp tab – dimenzije, safe area, colorScheme, refreshRate, focus.
//

import SwiftUI
import AppKit
import Combine

/// Okruženje ekrana – reaktivno, mijenja se kad se promijeni viewport/focus/theme
final class ScreenEnvironment: ObservableObject {
    /// Inkrementira se pri svakoj promjeni – za .onChange(of: env.changeVersion)
    @Published private(set) var changeVersion: Int = 0
    // MARK: - Osnovne dimenzije
    @Published var widthPx: CGFloat = 0
    @Published var heightPx: CGFloat = 0
    @Published var scale: CGFloat = 2.0  // Retina / DPI
    @Published var aspectRatio: CGFloat = 0
    
    // MARK: - Prostor i sigurni rubovi
    @Published var safeAreaTop: CGFloat = 0
    @Published var safeAreaBottom: CGFloat = 0
    @Published var safeAreaLeading: CGFloat = 0
    @Published var safeAreaTrailing: CGFloat = 0
    @Published var viewportWidth: CGFloat = 0
    @Published var viewportHeight: CGFloat = 0
    @Published var keyboardHeight: CGFloat = 0
    
    // MARK: - Stanje prozora
    @Published var isFullscreen: Bool = false
    @Published var isFocused: Bool = true
    @Published var isVisible: Bool = true
    
    // MARK: - Input okruženje
    @Published var pointerType: String = "mouse"
    @Published var hoverAvailable: Bool = true
    @Published var keyboardAvailable: Bool = true
    
    // MARK: - Vizualne postavke
    @Published var colorScheme: String = "dark"  // "light" | "dark"
    @Published var contrastMode: String = "normal"
    @Published var reducedMotion: Bool = false
    
    // MARK: - Performanse
    @Published var refreshRate: Double = 60
    @Published var frameBudgetMs: Double = 16.67
    
    // MARK: - Orijentacija
    @Published var orientation: String = "landscape"  // "portrait" | "landscape"
    @Published var rotationAngle: Double = 0
    
    /// JSON reprezentacija konteksta (za Swift app)
    var jsonContext: [String: Any] {
        [
            "widthPx": widthPx,
            "heightPx": heightPx,
            "scale": scale,
            "aspectRatio": aspectRatio,
            "safeArea": ["top": safeAreaTop, "bottom": safeAreaBottom, "leading": safeAreaLeading, "trailing": safeAreaTrailing],
            "viewportFrame": ["width": viewportWidth, "height": viewportHeight],
            "keyboardHeight": keyboardHeight,
            "isFullscreen": isFullscreen,
            "isFocused": isFocused,
            "isVisible": isVisible,
            "colorScheme": colorScheme,
            "refreshRate": refreshRate,
            "orientation": orientation
        ]
    }
    
    func update(from geometry: GeometryProxy, colorScheme: ColorScheme, isVisible: Bool) {
        updateFrom(size: geometry.size, insets: geometry.safeAreaInsets, colorScheme: colorScheme, isVisible: isVisible)
    }
    
    func updateFrom(size: CGSize, insets: EdgeInsets, colorScheme: ColorScheme, isVisible: Bool) {
        widthPx = size.width
        heightPx = size.height
        viewportWidth = size.width
        viewportHeight = size.height
        aspectRatio = heightPx > 0 ? widthPx / heightPx : 0
        scale = NSScreen.main?.backingScaleFactor ?? 2.0
        safeAreaTop = insets.top
        safeAreaBottom = insets.bottom
        safeAreaLeading = insets.leading
        safeAreaTrailing = insets.trailing
        self.colorScheme = colorScheme == .dark ? "dark" : "light"
        self.isVisible = isVisible
        refreshRate = 60  // CVDisplayLink za stvarni refresh; default 60Hz
        frameBudgetMs = refreshRate > 0 ? 1000 / refreshRate : 16.67
        orientation = widthPx > heightPx ? "landscape" : "portrait"
        changeVersion += 1
    }
    
    func updateFocus(_ focused: Bool) {
        isFocused = focused
        isVisible = focused
        changeVersion += 1
    }
}

// MARK: - Modifier za onScreenChange callback
struct OnScreenChangeModifier: ViewModifier {
    @Environment(\.screenEnvironment) private var env
    let action: (ScreenEnvironment) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: env?.changeVersion ?? 0) { _, _ in
                if let env { action(env) }
            }
    }
}

extension View {
    func onScreenChange(perform action: @escaping (ScreenEnvironment) -> Void) -> some View {
        modifier(OnScreenChangeModifier(action: action))
    }
}

// MARK: - Environment key
private struct ScreenEnvironmentKey: EnvironmentKey {
    static let defaultValue: ScreenEnvironment? = nil
}

extension EnvironmentValues {
    var screenEnvironment: ScreenEnvironment? {
        get { self[ScreenEnvironmentKey.self] }
        set { self[ScreenEnvironmentKey.self] = newValue }
    }
}

// MARK: - Preference za reaktivno ažuriranje (Equatable da onPreferenceChange radi)
private struct ScreenGeometryValue: Equatable {
    let size: CGSize
    let insets: EdgeInsets
}

private struct ScreenGeometryPreferenceKey: PreferenceKey {
    static var defaultValue: ScreenGeometryValue? { nil }
    static func reduce(value: inout ScreenGeometryValue?, nextValue: () -> ScreenGeometryValue?) {
        value = nextValue()
    }
}

// MARK: - View modifier – injektira ScreenEnvironment u svaki screen element
struct ScreenEnvironmentModifier: ViewModifier {
    @StateObject private var env = ScreenEnvironment()
    @Environment(\.colorScheme) private var colorScheme
    let isSelectedTab: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScreenGeometryPreferenceKey.self,
                            value: ScreenGeometryValue(size: geometry.size, insets: geometry.safeAreaInsets)
                        )
                }
            )
            .onPreferenceChange(ScreenGeometryPreferenceKey.self) { value in
                guard let value else { return }
                env.updateFrom(size: value.size, insets: value.insets, colorScheme: colorScheme, isVisible: isSelectedTab)
            }
            .onAppear {
                env.updateFocus(isSelectedTab)
            }
            .onChange(of: isSelectedTab) { _, new in
                env.updateFocus(new)
            }
            .environment(\.screenEnvironment, env)
    }
}

extension View {
    func screenEnvironment(isSelectedTab: Bool = true) -> some View {
        modifier(ScreenEnvironmentModifier(isSelectedTab: isSelectedTab))
    }
}
