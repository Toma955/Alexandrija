//
//  ConsoleView.swift
//  Alexandria
//
//  Console UI – prikaz log poruka.
//

import SwiftUI
import AppKit

struct ConsoleView: View {
    @ObservedObject var store: ConsoleStore
    var onCollapse: (() -> Void)?
    private let accentColor = Color(hex: "ff5c00")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Console")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
                Spacer()
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
            .background(Color.black.opacity(0.85))
        }
        .frame(height: 120)
    }
    
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
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
