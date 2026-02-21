//
//  ScreenEnvironment.swift
//  Alexandria
//
//  Reaktivno okruženje ekrana za webapp tab – dimenzije, safe area, colorScheme, refreshRate, focus.
//

import SwiftUI
import AppKit
import Combine

// MARK: - Način prikaza prozora (full / half / quarter / windowed)

enum WindowLayoutMode: String, Equatable {
    case fullScreen
    case halfScreen
    case quarterScreen
    case windowed
}

/// Globalni promatrač stanja prozora – ažurira se iz WindowAccessor kad se prozor promijeni.
/// NE DIRAJ: @Published se smije mijenjati samo unutar DispatchQueue.main.async – inače "Publishing changes from within view updates".
final class WindowLayoutObserver: ObservableObject {
    static let shared = WindowLayoutObserver()

    @Published private(set) var isFullscreen: Bool = false
    @Published private(set) var layoutMode: WindowLayoutMode = .windowed

    private var windowObservers: [NSObjectProtocol] = []

    private init() {}

    /// Pozovi kad imaš referencu na prozor (npr. iz WindowAccessor) i kad se prozor mijenja.
    func updateFromWindow(_ window: NSWindow?) {
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
        windowObservers = []

        guard let window = window else {
            DispatchQueue.main.async { [weak self] in
                self?.isFullscreen = false
                self?.layoutMode = .windowed
            }
            return
        }

        updateState(window: window)

        let obs1 = NotificationCenter.default.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window, queue: .main) { [weak self] _ in
            self?.updateState(window: window)
        }
        let obs2 = NotificationCenter.default.addObserver(forName: NSWindow.didExitFullScreenNotification, object: window, queue: .main) { [weak self] _ in
            self?.updateState(window: window)
        }
        let obs3 = NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { [weak self] _ in
            self?.updateState(window: window)
        }
        windowObservers = [obs1, obs2, obs3]
    }

    private func updateState(window: NSWindow) {
        let fullScreen = window.styleMask.contains(.fullScreen)
        let newLayoutMode: WindowLayoutMode

        guard let screen = window.screen ?? NSScreen.main else {
            newLayoutMode = fullScreen ? .fullScreen : .windowed
            DispatchQueue.main.async { [weak self] in
                self?.isFullscreen = fullScreen
                self?.layoutMode = newLayoutMode
            }
            return
        }
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame

        if fullScreen {
            newLayoutMode = .fullScreen
            DispatchQueue.main.async { [weak self] in
                self?.isFullscreen = fullScreen
                self?.layoutMode = newLayoutMode
            }
            return
        }

        let screenArea = screenFrame.width * screenFrame.height
        let windowArea = windowFrame.width * windowFrame.height
        guard screenArea > 0 else {
            newLayoutMode = .windowed
            DispatchQueue.main.async { [weak self] in
                self?.isFullscreen = fullScreen
                self?.layoutMode = newLayoutMode
            }
            return
        }
        let ratio = windowArea / screenArea
        if ratio >= 0.85 {
            newLayoutMode = .fullScreen
        } else if ratio >= 0.35 && ratio < 0.65 {
            newLayoutMode = .halfScreen
        } else if ratio >= 0.15 && ratio < 0.40 {
            newLayoutMode = .quarterScreen
        } else {
            newLayoutMode = .windowed
        }
        DispatchQueue.main.async { [weak self] in
            self?.isFullscreen = fullScreen
            self?.layoutMode = newLayoutMode
        }
    }
}

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
    
    // MARK: - Stanje prozora (ažurira se iz WindowLayoutObserver)
    @Published var isFullscreen: Bool = false
    @Published var windowLayoutMode: WindowLayoutMode = .windowed
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
            "windowLayoutMode": windowLayoutMode.rawValue,
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

    /// Ažurira stanje prozora (full / half / quarter) iz WindowLayoutObserver.
    func updateWindowLayout(isFullscreen: Bool, layoutMode: WindowLayoutMode) {
        guard self.isFullscreen != isFullscreen || self.windowLayoutMode != layoutMode else { return }
        self.isFullscreen = isFullscreen
        self.windowLayoutMode = layoutMode
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
    @ObservedObject private var windowLayout = WindowLayoutObserver.shared
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
                // NE DIRAJ: async da se ne publisha tijekom view updatea
                DispatchQueue.main.async {
                    env.updateFrom(size: value.size, insets: value.insets, colorScheme: colorScheme, isVisible: isSelectedTab)
                }
            }
            .onAppear {
                env.updateFocus(isSelectedTab)
                env.updateWindowLayout(isFullscreen: windowLayout.isFullscreen, layoutMode: windowLayout.layoutMode)
            }
            .onChange(of: isSelectedTab) { _, new in
                env.updateFocus(new)
            }
            .onChange(of: windowLayout.isFullscreen) { _, full in
                env.updateWindowLayout(isFullscreen: full, layoutMode: windowLayout.layoutMode)
            }
            .onChange(of: windowLayout.layoutMode) { _, mode in
                env.updateWindowLayout(isFullscreen: windowLayout.isFullscreen, layoutMode: mode)
            }
            .environment(\.screenEnvironment, env)
    }
}

extension View {
    func screenEnvironment(isSelectedTab: Bool = true) -> some View {
        modifier(ScreenEnvironmentModifier(isSelectedTab: isSelectedTab))
    }
}
