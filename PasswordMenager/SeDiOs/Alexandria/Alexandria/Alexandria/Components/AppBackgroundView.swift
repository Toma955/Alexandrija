//
//  AppBackgroundView.swift
//  Alexandria
//
//  Nilternius-inspired animated blob background
//

import SwiftUI

private struct BlobLobe {
    let angle: CGFloat
    let offsetFactor: CGFloat
    let radiusFactor: CGFloat
}

private struct Blob: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var r: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var color: Color
    var lobes: [BlobLobe]
}

struct AppBackgroundView: View {
    @State private var blobs: [Blob] = []
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                Canvas { context, size in
                    guard !blobs.isEmpty else { return }
                    
                    let minDim = min(size.width, size.height)
                    let blurRadius = max(3, min(minDim / 50, 20))
                    context.addFilter(.blur(radius: blurRadius))
                    context.blendMode = .normal

                    for blob in blobs {
                        var path = Path()
                        path.addEllipse(in: CGRect(
                            x: blob.x - blob.r,
                            y: blob.y - blob.r,
                            width: blob.r * 2,
                            height: blob.r * 2
                        ))

                        for lobe in blob.lobes {
                            let offsetR = blob.r * lobe.offsetFactor
                            let offsetX = cos(lobe.angle) * offsetR
                            let offsetY = sin(lobe.angle) * offsetR
                            let nodeRadius = blob.r * lobe.radiusFactor
                            path.addEllipse(in: CGRect(
                                x: blob.x + offsetX - nodeRadius,
                                y: blob.y + offsetY - nodeRadius,
                                width: nodeRadius * 2,
                                height: nodeRadius * 2
                            ))
                        }
                        context.fill(path, with: .color(blob.color.opacity(0.6)))
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                if geo.size.width > 0 && geo.size.height > 0 {
                    setupBlobs(in: geo.size)
                }
            }
            .onChange(of: geo.size) { _, newSize in
                if newSize.width > 0 && newSize.height > 0 {
                    setupBlobs(in: newSize)
                }
            }
            .onReceive(timer) { _ in
                if geo.size.width > 0 && geo.size.height > 0 && !blobs.isEmpty {
                    updateBlobs(in: geo.size)
                }
            }
        }
    }

    private func setupBlobs(in size: CGSize) {
        let width = size.width
        let height = size.height
        guard width > 0, height > 0 else { return }

        let colors: [Color] = [
            Color(red: 1.00, green: 0.36, blue: 0.00), // ff5c00
            Color(red: 0.95, green: 0.20, blue: 0.20),
            Color(red: 1.00, green: 0.55, blue: 0.10),
            Color(red: 0.95, green: 0.30, blue: 0.15)
        ]

        let minDimension = min(width, height)
        let baseTotal = minDimension < 200 ? 40 : 45
        let areaFactor = max((width * height) / (800 * 800), 0.4)
        let total = Int(CGFloat(baseTotal) * areaFactor)

        var tmp: [Blob] = []
        for _ in 0..<total {
            let baseMaxR = min(minDimension / 3.5, 80)
            let minR = max(25, baseMaxR * 0.45)
            let r = CGFloat.random(in: minR...baseMaxR)

            let x = width > 2 * r ? CGFloat.random(in: r...(width - r)) : width / 2
            let y = height > 2 * r ? CGFloat.random(in: r...(height - r)) : height / 2

            let speed = CGFloat.random(in: 0.07...0.18)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            let color = colors.randomElement() ?? colors[0]

            var lobes: [BlobLobe] = []
            for i in 0..<Int.random(in: 3...5) {
                let t = CGFloat(i) / 5
                let a = t * .pi * 2 + CGFloat.random(in: -0.4...0.4)
                lobes.append(BlobLobe(
                    angle: a,
                    offsetFactor: CGFloat.random(in: 0.3...0.8),
                    radiusFactor: CGFloat.random(in: 0.5...0.9)
                ))
            }

            tmp.append(Blob(x: x, y: y, r: r, dx: dx, dy: dy, color: color, lobes: lobes))
        }
        blobs = tmp
    }

    private func updateBlobs(in size: CGSize) {
        let width = size.width
        let height = size.height
        let margin: CGFloat = 60

        blobs = blobs.map { blob in
            var b = blob
            b.x += b.dx
            b.y += b.dy
            if b.x < margin || b.x > width - margin { b.dx = -b.dx }
            if b.y < margin || b.y > height - margin { b.dy = -b.dy }
            return b
        }
    }
}

#Preview {
    AppBackgroundView()
        .frame(width: 800, height: 600)
}
