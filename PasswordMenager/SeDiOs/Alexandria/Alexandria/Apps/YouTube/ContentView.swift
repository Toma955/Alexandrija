//
//  ContentView.swift
//  YouTube – realistična replika (header, sidebar, grid videa)
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

private let ytBg = hex("0f0f0f")
private let ytHeader = hex("212121")
private let ytSidebar = hex("212121")
private let ytCard = hex("181818")
private let ytRed = hex("ff0000")
private let ytGray = hex("aaaaaa")
private let ytGrayDim = hex("717171")

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header – kao pravi YouTube
            HStack(spacing: 0) {
                Button { } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(ytRed)
                    Text("YouTube")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 4)

                Spacer()

                HStack(spacing: 8) {
                    TextField("Pretraži", text: .constant(""))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(hex("121212"))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(hex("303030"), lineWidth: 1)
                        )
                        .frame(width: 520)
                        .overlay(alignment: .leading) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(ytGrayDim)
                                .padding(.leading, 14)
                        }

                    Button { } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(hex("181818"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 4) {
                    Button { } label: {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 48)
                    }
                    .buttonStyle(.plain)
                    Button { } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 48)
                    }
                    .buttonStyle(.plain)
                    Button { } label: {
                        Circle()
                            .fill(ytGray)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 16)
            }
            .frame(height: 56)
            .background(ytHeader)

            HStack(alignment: .top, spacing: 0) {
                // Sidebar – Home, Shorts, Subscriptions, Library
                VStack(alignment: .leading, spacing: 0) {
                    sidebarRow(icon: "house.fill", label: "Početna", selected: true)
                    sidebarRow(icon: "bolt.fill", label: "Shorts", selected: false)
                    sidebarRow(icon: "rectangle.stack.fill", label: "Pretplate", selected: false)
                    sidebarRow(icon: "play.rectangle.fill", label: "Biblioteka", selected: false)
                    sidebarRow(icon: "clock.fill", label: "Povijest", selected: false)
                    Divider().background(ytGrayDim.opacity(0.3)).padding(.vertical, 12)
                    Text("Pretplate")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ytGrayDim)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    sidebarRow(icon: "person.2.fill", label: "Kanal 1", selected: false)
                    sidebarRow(icon: "person.2.fill", label: "Kanal 2", selected: false)
                    Spacer()
                }
                .frame(width: 240)
                .background(ytSidebar)
                .padding(.top, 0)

                Divider()
                    .frame(width: 1)
                    .background(ytGrayDim.opacity(0.2))

                // Glavni sadržaj – grid videa
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 320), spacing: 16)
                    ], spacing: 24) {
                        ForEach(0..<8, id: \.self) { i in
                            videoCard(
                                title: videoTitles[i],
                                channel: videoChannels[i],
                                views: videoViews[i],
                                duration: videoDurations[i]
                            )
                        }
                    }
                    .padding(24)
                }
                .background(ytBg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ytBg)
    }

    private func sidebarRow(icon: String, label: String, selected: Bool) -> some View {
        HStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(selected ? .white : ytGrayDim)
                .frame(width: 24, alignment: .center)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(selected ? .white : ytGrayDim)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(selected ? hex("303030") : Color.clear)
    }

    private func videoCard(title: String, channel: String, views: String, duration: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(hex("272727"))
                    .aspectRatio(16/9, contentMode: .fit)
                Text(duration)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(4)
                    .padding(8)
            }

            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(hex("3f3f3f"))
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text(channel)
                        .font(.system(size: 12))
                        .foregroundColor(ytGrayDim)
                    Text(views)
                        .font(.system(size: 12))
                        .foregroundColor(ytGrayDim)
                }
                Spacer()
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 360)
    }
}

private let videoTitles = [
    "Naslov videa koji može biti duži – kanal",
    "Kako napraviti nešto u 5 minuta",
    "Tutorial: SwiftUI za početnike",
    "Vijesti dana – sažetak",
    "Muzika za rad i fokus",
    "Gaming highlight – najbolji momenti",
    "Recenzija novog uređaja",
    "Podcast #42 – tema razgovora"
]
private let videoChannels = [
    "Kanal Alpha", "Tech Channel", "Swift Dev", "Vijesti", "Lo-fi Beats", "Gamer", "Review Hub", "Podcast Show"
]
private let videoViews = [
    "1,2 mln pregleda · prije 2 dana",
    "45 tis. pregleda · prije 1 tjedan",
    "12 tis. pregleda · prije 3 dana",
    "89 tis. pregleda · prije 1 dan",
    "2,1 mln pregleda · prije 1 mj.",
    "234 tis. pregleda · prije 5 dana",
    "67 tis. pregleda · prije 2 tjedna",
    "8 tis. pregleda · prije 1 dan"
]
private let videoDurations = [
    "12:34", "5:21", "18:09", "4:45", "1:00:00", "8:12", "15:33", "42:18"
]

#Preview {
    ContentView()
        .frame(width: 1280, height: 800)
}
