//
//  MessageBubbleView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isHighlighted: Bool
    let textScale: CGFloat
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df
    }()
    
    var body: some View {
        let timeText = Self.timeFormatter.string(from: message.timestamp)
        
        switch message.direction {
        case .system:
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 11 * textScale, weight: .medium))
                    Text(timeText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(6)
                .background(
                    Capsule()
                        .fill(isHighlighted
                              ? Color.white.opacity(0.30)
                              : Color.white.opacity(0.12))
                )
                Spacer()
            }
            
        case .incoming:
            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 13 * textScale))
                    Text(timeText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHighlighted
                              ? Color.white.opacity(0.25)
                              : Color.white.opacity(0.12))
                )
                Spacer(minLength: 20)
            }
            
        case .outgoing:
            HStack(alignment: .bottom, spacing: 6) {
                Spacer(minLength: 20)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(message.text)
                        .font(.system(size: 13 * textScale))
                    Text(timeText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHighlighted
                              ? Color.green.opacity(0.9)
                              : Color.green.opacity(0.7))
                )
            }
        }
    }
}

