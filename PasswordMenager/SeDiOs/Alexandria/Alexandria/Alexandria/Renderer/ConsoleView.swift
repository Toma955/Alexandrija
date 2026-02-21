//
//  ConsoleView.swift
//  Alexandria
//
//  Console UI – prikaz log poruka.
//

import SwiftUI
import AppKit

/// 6 faza prozirnosti: 0 = 0%, 1 = 20%, 2 = 40%, 3 = 60%, 4 = 80%, 5 = 100%
private let consoleOpacityPhaseCount = 6
private func consoleOpacity(fromPhase phase: Int) -> Double {
    guard phase >= 0, phase < consoleOpacityPhaseCount else { return 0.85 }
    return Double(phase) / Double(consoleOpacityPhaseCount - 1)
}

struct ConsoleView: View {
    @ObservedObject var store: ConsoleStore
    var onCollapse: (() -> Void)?
    /// Prozirnost pozadine: 0 = potpuno prozirno, 1 = potpuno crna. Ako nil, koristi 0.85.
    var backgroundOpacity: Double? = nil
    /// Kad postoji, u headeru se prikazuju + i − za 6 faza prozirnosti (0–5); opacity = phase/5.
    var opacityPhase: Binding<Int>? = nil
    /// Kad true, konzola raste na cijelu visinu (npr. overlay iznad cijelog ekrana).
    var expandVertically: Bool = false
    private let accentColor = Color(hex: "ff5c00")
    private var effectiveBackgroundOpacity: Double {
        if let binding = opacityPhase { return consoleOpacity(fromPhase: binding.wrappedValue) }
        return backgroundOpacity ?? 0.85
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Console")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Spacer()
                if let binding = opacityPhase {
                    Button {
                        if binding.wrappedValue > 0 { binding.wrappedValue -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(accentColor)
                    .buttonStyle(.plain)
                    Text("\(binding.wrappedValue + 1)/\(consoleOpacityPhaseCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(minWidth: 28)
                    Button {
                        if binding.wrappedValue < consoleOpacityPhaseCount - 1 { binding.wrappedValue += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(accentColor)
                    .buttonStyle(.plain)
                }
                Button("Copy") {
                    copyToClipboard()
                }
                .font(.system(size: 11))
                .foregroundColor(accentColor)
                Button("Clear") {
                    store.clear()
                }
                .font(.system(size: 11))
                .foregroundColor(accentColor)
                if onCollapse != nil {
                    Button {
                        onCollapse?()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(accentColor)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.5))
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.messages) { msg in
                            HStack(alignment: .top, spacing: 8) {
                                Text(formatTime(msg.date))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.4))
                                Text(msg.text)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(colorFor(msg.type))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .onChange(of: store.messages.count) { _, _ in
                    if let last = store.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(effectiveBackgroundOpacity))
        }
        .frame(height: expandVertically ? nil : 120)
        .frame(maxHeight: expandVertically ? .infinity : nil)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM. HH:mm:ss"
        return f.string(from: date)
    }
    
    private func colorFor(_ type: ConsoleMessageType) -> Color {
        switch type {
        case .log: return .white.opacity(0.9)
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        }
    }
    
    private func copyToClipboard() {
        let text = store.messages.map { msg in
            "[\(formatTime(msg.date))] \(msg.text)"
        }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
