import SwiftUI

/// The night-sky backdrop used on every screen: near-black purple base,
/// soft nebula glows, and a seeded scatter of stars and four-point sparkles.
/// Seeded so the sky is stable across renders.
struct StarfieldBackground: View {
    var body: some View {
        ZStack {
            Theme.bgBase

            RadialGradient(
                colors: [Theme.bgGlow.opacity(0.55), .clear],
                center: UnitPoint(x: 0.5, y: 1.05),
                startRadius: 20,
                endRadius: 440
            )

            RadialGradient(
                colors: [Theme.bgGlow.opacity(0.30), .clear],
                center: UnitPoint(x: 0.9, y: 0.1),
                startRadius: 10,
                endRadius: 320
            )

            Canvas { context, size in
                var rng = SeededRandom(seed: 0xC0FFEE)

                for _ in 0..<90 {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height
                    let radius = 0.5 + rng.next() * 1.2
                    let alpha = 0.10 + rng.next() * 0.40
                    let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }

                for _ in 0..<7 {
                    let center = CGPoint(x: rng.next() * size.width, y: rng.next() * size.height)
                    let arm = 3.0 + rng.next() * 4.0
                    let alpha = 0.25 + rng.next() * 0.35
                    context.fill(
                        Self.sparklePath(center: center, arm: arm),
                        with: .color(Theme.accentBright.opacity(alpha))
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Classic four-point sparkle: tips at N/E/S/W pinched through the center.
    static func sparklePath(center c: CGPoint, arm: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - arm))
        path.addQuadCurve(to: CGPoint(x: c.x + arm, y: c.y), control: c)
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + arm), control: c)
        path.addQuadCurve(to: CGPoint(x: c.x - arm, y: c.y), control: c)
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - arm), control: c)
        return path
    }
}

/// Tiny deterministic LCG so decorative layouts don't reshuffle every render.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    /// Returns a value in [0, 1).
    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) % 10_000) / 10_000
    }
}
