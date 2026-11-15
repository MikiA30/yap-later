import SwiftUI

/// Played once when the app opens: speech bubbles rise from the bottom of the screen and leave through the top.
/// A few of them say hello. They never block touches, and they are skipped when Reduce Motion is on.
struct LaunchBubbles: View {
    var onFinished: () -> Void
    @State private var start = Date.now

    private struct Bubble: Identifiable {
        let id: Int
        /// Horizontal position, 0...1 across the screen.
        let x: CGFloat
        let size: CGFloat
        let delay: Double
        let duration: Double
        let sway: CGFloat
        let word: String?
        let color: Color
    }

    private static let bubbles: [Bubble] = [
        Bubble(id: 0, x: 0.20, size: 92, delay: 0.00, duration: 2.5, sway: 14, word: "hello", color: Theme.brand),
        Bubble(id: 1, x: 0.74, size: 44, delay: 0.10, duration: 2.1, sway: 10, word: nil, color: Theme.lemon),
        Bubble(id: 2, x: 0.48, size: 28, delay: 0.25, duration: 1.9, sway: 8, word: nil, color: Theme.color(for: .transport)),
        Bubble(id: 3, x: 0.86, size: 76, delay: 0.40, duration: 2.6, sway: 12, word: "hi", color: Theme.color(for: .groceries)),
        Bubble(id: 4, x: 0.08, size: 36, delay: 0.55, duration: 2.0, sway: 9, word: nil, color: Theme.color(for: .fun)),
        Bubble(id: 5, x: 0.60, size: 84, delay: 0.70, duration: 2.7, sway: 16, word: "hey", color: Theme.color(for: .shopping)),
        Bubble(id: 6, x: 0.34, size: 22, delay: 0.85, duration: 1.8, sway: 6, word: nil, color: Theme.brand),
        Bubble(id: 7, x: 0.92, size: 30, delay: 1.00, duration: 2.0, sway: 8, word: nil, color: Theme.color(for: .health)),
        Bubble(id: 8, x: 0.16, size: 70, delay: 1.10, duration: 2.5, sway: 12, word: "yo", color: Theme.color(for: .bills)),
        Bubble(id: 9, x: 0.52, size: 40, delay: 1.25, duration: 2.1, sway: 10, word: nil, color: Theme.lemon),
        Bubble(id: 10, x: 0.76, size: 88, delay: 1.40, duration: 2.6, sway: 14, word: "hola", color: Theme.brand),
        Bubble(id: 11, x: 0.30, size: 32, delay: 1.55, duration: 1.9, sway: 8, word: nil, color: Theme.color(for: .dining)),
    ]

    private static let total = (bubbles.map { $0.delay + $0.duration }.max() ?? 0) + 0.1

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSince(start)
                ZStack {
                    ForEach(Self.bubbles) { bubble in
                        let progress = min(max((elapsed - bubble.delay) / bubble.duration, 0), 1)
                        // Bubbles speed up a little as they rise.
                        let risen = CGFloat(pow(progress, 1.25))
                        let travel = proxy.size.height + bubble.size * 2
                        bubbleView(bubble)
                            .position(x: bubble.x * proxy.size.width
                                        + CGFloat(sin(elapsed * 2.4 + Double(bubble.id))) * bubble.sway,
                                      y: proxy.size.height + bubble.size - travel * risen)
                            .opacity(progress > 0 && progress < 1 ? 1 : 0)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            // Tied to this view's lifetime: remove the layer once the last bubble has left.
            try? await Task.sleep(for: .seconds(Self.total))
            onFinished()
        }
    }

    private func bubbleView(_ bubble: Bubble) -> some View {
        ZStack {
            Circle().fill(bubble.color.opacity(bubble.word == nil ? 0.22 : 0.92))
            Circle().strokeBorder(bubble.color, lineWidth: 2)
            // The glint that makes a circle read as a bubble.
            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: bubble.size * 0.18, height: bubble.size * 0.18)
                .offset(x: -bubble.size * 0.22, y: -bubble.size * 0.24)
            if let word = bubble.word {
                Text(word)
                    .font(Theme.display(bubble.size * 0.27))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: bubble.size, height: bubble.size)
    }
}
