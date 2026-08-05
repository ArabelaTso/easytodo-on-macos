import SwiftUI

struct CompletionFireworksView: View {
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [FireworkBurst] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(bursts) { burst in
                    FireworkBurstView(burst: burst)
                        .position(x: proxy.size.width - 76, y: 70)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            showBurst()
        }
    }

    private func showBurst() {
        guard !reduceMotion else { return }

        let burst = FireworkBurst.make()
        bursts.append(burst)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            bursts.removeAll { $0.id == burst.id }
        }
    }
}

private struct FireworkBurstView: View {
    let burst: FireworkBurst

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            ForEach(burst.particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(isExpanded ? 0.2 : 1)
                    .opacity(isExpanded ? 0 : 1)
                    .offset(
                        x: isExpanded ? particle.offset.width : 0,
                        y: isExpanded ? particle.offset.height : 0
                    )
                    .animation(
                        .easeOut(duration: 0.52).delay(particle.delay),
                        value: isExpanded
                    )
            }
        }
        .onAppear {
            isExpanded = true
        }
    }
}

private struct FireworkBurst: Identifiable {
    let id: UUID
    let particles: [FireworkParticle]

    static func make() -> FireworkBurst {
        let colors = [
            Color(red: 0.78, green: 0.18, blue: 0.15),
            Color(red: 0.86, green: 0.62, blue: 0.18),
            Color(red: 0.22, green: 0.54, blue: 0.36),
            Color(red: 0.82, green: 0.78, blue: 0.68)
        ]

        let particles = (0..<14).map { index in
            let angle = Double(index) / 14.0 * Double.pi * 2.0
            let distance = 26.0 + Double(index % 4) * 5.0

            return FireworkParticle(
                offset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                color: colors[index % colors.count],
                size: CGFloat(3 + index % 3),
                delay: Double(index % 5) * 0.018
            )
        }

        return FireworkBurst(id: UUID(), particles: particles)
    }
}

private struct FireworkParticle: Identifiable {
    let id = UUID()
    let offset: CGSize
    let color: Color
    let size: CGFloat
    let delay: Double
}
