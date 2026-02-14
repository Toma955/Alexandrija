//
//  ContentView.swift
//  YouTube – vjerna replika layouta (tamna tema, header, preporučeno, link)
//

import SwiftUI

private func hex(_ s: String) -> Color {
    let hex = s.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF) / 255
    let g = Double((int >> 8) & 0xFF) / 255
    let b = Double(int & 0xFF) / 255
    return Color(red: r, green: g, blue: b)
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header – tamna pozadina
            ZStack(alignment: .leading) {
                hex("1a1a1a")
                HStack(spacing: 16) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red)
                    Text("YouTube")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    TextField("Pretraži", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                    Button("Prijava") { }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(hex("3ea6ff"))
                        .cornerRadius(4)
                }
                .padding(16)
            }
            .frame(height: 56)

            Divider()
                .background(Color.white.opacity(0.2))

            // Sadržaj – scroll
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Preporučeno")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(alignment: .top, spacing: 16) {
                        // Video kartica 1
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(hex("333333"))
                                    .frame(width: 280, height: 158)
                            }
                            Text("Naslov videa – kanal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Text("Pregledi · prije 2 dana")
                                .font(.system(size: 12))
                                .foregroundColor(hex("888888"))
                        }
                        .frame(width: 280, alignment: .leading)

                        Spacer()

                        // Video kartica 2
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(hex("333333"))
                                    .frame(width: 280, height: 158)
                            }
                            Text("Drugi video – drugi kanal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            Text("Pregledi · prije 1 tjedan")
                                .font(.system(size: 12))
                                .foregroundColor(hex("888888"))
                        }
                        .frame(width: 280, alignment: .leading)
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)

                    Text("Otvori pravi YouTube:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))

                    Link("youtube.com", destination: URL(string: "https://www.youtube.com")!)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(hex("3ea6ff"))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(hex("1a1a1a"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(hex("1a1a1a"))
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
