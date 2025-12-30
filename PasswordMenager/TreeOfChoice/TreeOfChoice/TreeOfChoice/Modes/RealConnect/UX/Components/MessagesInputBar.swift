//
//  MessagesInputBar.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct MessagesInputBar: View {
    @Binding var messageText: String
    let sendOnEnter: Bool
    
    let controlSize: CGFloat
    let barWidth: CGFloat
    let barHeight: CGFloat
    
    let onSend: (String) -> Void
    
    private func send() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSend(text)
        messageText = ""
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // + datoteke
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.36, blue: 0.0),
                            Color(red: 0.9, green: 0.15, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: controlSize, height: controlSize)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                )
            
            // input
            TextField("Napiši poruku…", text: $messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: controlSize)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .foregroundColor(.black)
                .onSubmit {
                    if sendOnEnter {
                        send()
                    }
                }
            
            // send
            Button {
                send()
            } label: {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.2, green: 0.85, blue: 0.45))
                    .frame(width: 55, height: controlSize)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(width: barWidth, height: barHeight)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
    }
}

