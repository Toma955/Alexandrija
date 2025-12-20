// App/SharedUX/Components/ModeCard.swift
import SwiftUI

struct ModeCard: View {
    let title: String
    let description: String
    let buttonTitle: String
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline.bold())
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(accentColor.opacity(0.9))
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 230, height: 230)
        .background(
            Color.black.opacity(0.80)       // tamno "staklo"
        )
        .cornerRadius(20)
    }
}
