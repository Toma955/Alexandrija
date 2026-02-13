//
//  Eluminatium.swift
//  Alexandria
//
//  Pretraživač - pozadina i search engine.
//

import SwiftUI
import AppKit

// MARK: - Search TextField – radi ispravno, bez žutog/znaka zabrane
private struct SearchTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField(string: text)
        tf.placeholderString = placeholder
        tf.isBordered = false
        tf.drawsBackground = false
        tf.isEditable = true
        tf.isSelectable = true
        tf.focusRingType = .none
        tf.textColor = .white
        tf.font = .systemFont(ofSize: 14)
        if let cell = tf.cell as? NSTextFieldCell {
            cell.placeholderAttributedString = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: NSColor.gray]
            )
        }
        tf.delegate = context.coordinator
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        nsView.placeholderString = placeholder
        nsView.textColor = .white
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text = field.stringValue
        }
    }
}

struct EluminatiumView: View {
    @State private var showSettings = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                Spacer()
                SearchEngineSection(onOpenSettings: { showSettings = true })
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Search Engine
struct SearchEngineSection: View {
    @State private var isHovering = false
    @State private var searchText = ""
    var onOpenSettings: (() -> Void)?

    private let accentColor = Color(hex: "ff5c00")

    var body: some View {
        HoverProximityZone(isHovering: $isHovering, proximityPadding: 80) {
            VStack(spacing: isHovering ? 24 : 12) {
                SearchBar(searchText: $searchText, accentColor: accentColor)

                if isHovering {
                    SearchSettingsRow(accentColor: accentColor, onOpenSettings: onOpenSettings)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(24)
            .frame(maxWidth: 440)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isHovering ? accentColor.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: isHovering ? 24 : 12, x: 0, y: 8)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isHovering)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var searchText: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(accentColor)

            SearchTextField(
                placeholder: "Pretraži aplikacije ili unesi URL...",
                text: $searchText
            )
            .frame(maxWidth: .infinity)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Search Settings Row
struct SearchSettingsRow: View {
    let accentColor: Color
    var onOpenSettings: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            SearchSettingChip(icon: "globe", label: "Default engine", accentColor: accentColor)
            SearchSettingChip(icon: "lock.shield", label: "Private", accentColor: accentColor)
            SearchSettingChip(icon: "arrow.up.arrow.down", label: "Sort", accentColor: accentColor)
            SearchSettingChip(icon: "gearshape", label: "Više", accentColor: accentColor, action: onOpenSettings)
        }
    }
}

struct SearchSettingChip: View {
    let icon: String
    let label: String
    let accentColor: Color
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hover Proximity Zone
struct HoverProximityZone<Content: View>: View {
    @Binding var isHovering: Bool
    let proximityPadding: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(proximityPadding)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovering = hovering
            }
    }
}
