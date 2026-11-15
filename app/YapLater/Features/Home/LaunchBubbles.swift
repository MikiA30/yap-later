import SwiftUI

/// Played once when the app opens: speech bubbles rise from the bottom of the screen and leave through the top.
/// Some carry a few words about money, a couple just say hi. They never block touches, and they are skipped when Reduce Motion is on.
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
        Bubble(id: 0, x: 0.26, size: 58, delay: 0.00, duration: 2.5, sway: 12, word: "let's save", color: Theme.brand),
        Bubble(id: 1, x: 0.78, size: 44, delay: 0.10, duration: 2.1, sway: 10, word: nil, color: Theme.lemon),
        Bubble(id: 2, x: 0.50, size: 28, delay: 0.25, duration: 1.9, sway: 8, word: nil, color: Theme.color(for: .transport)),
        Bubble(id: 3, x: 0.74, size: 54, delay: 0.40, duration: 2.6, sway: 12, word: "cha-ching", color: Theme.color(for: .groceries)),
        Bubble(id: 4, x: 0.10, size: 36, delay: 0.55, duration: 2.0, sway: 9, word: nil, color: Theme.color(for: .fun)),
        Bubble(id: 5, x: 0.40, size: 62, delay: 0.70, duration: 2.7, sway: 14, word: "hi", color: Theme.color(for: .shopping)),
        Bubble(id: 6, x: 0.90, size: 22, delay: 0.85, duration: 1.8, sway: 6, word: nil, color: Theme.brand),
        Bubble(id: 7, x: 0.68, size: 56, delay: 0.95, duration: 2.4, sway: 10, word: "money moves", color: Theme.color(for: .bills)),
        Bubble(id: 8, x: 0.18, size: 60, delay: 1.10, duration: 2.5, sway: 12, word: "$$$", color: Theme.color(for: .health)),
        Bubble(id: 9, x: 0.54, size: 40, delay: 1.25, duration: 2.1, sway: 10, word: nil, color: Theme.lemon),
        Bubble(id: 10, x: 0.30, size: 56, delay: 1.40, duration: 2.6, sway: 14, word: "stack it", color: Theme.brand),
        Bubble(id: 11, x: 0.80, size: 60, delay: 1.55, duration: 2.5, sway: 10, word: "hey", color: Theme.color(for: .dining)),
        Bubble(id: 12, x: 0.46, size: 54, delay: 1.75, duration: 2.5, sway: 12, word: "you got this", color: Theme.color(for: .fun)),
        Bubble(id: 13, x: 0.14, size: 30, delay: 1.90, duration: 2.0, sway: 8, word: nil, color: Theme.color(for: .groceries)),
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

    @ViewBuilder
    private func bubbleView(_ bubble: Bubble) -> some View {
        if let word = bubble.word {
            // A speech bubble: as wide as what it says.
            Text(word)
                .font(Theme.display(bubble.size * 0.34))
                .foregroundStyle(.white)
                .padding(.horizontal, bubble.size * 0.36)
                .frame(minWidth: bubble.size, minHeight: bubble.size)
                .background(bubble.color, in: Capsule())
                .overlay(alignment: .topLeading) { glint(bubble.size).offset(x: bubble.size * 0.22, y: bubble.size * 0.16) }
                .fixedSize()
        } else {
            Circle()
                .fill(bubble.color.opacity(0.22))
                .overlay { Circle().strokeBorder(bubble.color, lineWidth: 2) }
                .overlay(alignment: .topLeading) { glint(bubble.size).offset(x: bubble.size * 0.22, y: bubble.size * 0.16) }
                .frame(width: bubble.size, height: bubble.size)
        }
    }

    /// The highlight that makes a shape read as a bubble.
    private func glint(_ size: CGFloat) -> some View {
        Circle().fill(.white.opacity(0.55)).frame(width: size * 0.16, height: size * 0.16)
    }
}
