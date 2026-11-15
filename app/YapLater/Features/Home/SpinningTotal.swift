import SwiftUI

/// The week's total as a thick, coin-like number standing upright. Swipe sideways and it spins around its
/// vertical axis with the speed of the swipe, then settles face-on. It also turns once when the total changes.
struct SpinningTotal: View {
    let cents: Int
    @State private var angle: Double = SpinningTotal.debugAngle
    @State private var dragStart: Double?
    @State private var settles = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion)) { context in
            // At rest the number rocks slowly from side to side, so its thickness is always visible.
            let sway = reduceMotion ? -16 : sin(context.date.timeIntervalSinceReferenceDate * 0.9) * 15
            ExtrudedAmount(text: Money.format(cents: cents), cents: cents, angle: angle, sway: sway)
        }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .gesture(reduceMotion ? nil : drag)
            .onTapGesture { if !reduceMotion { spin(to: angle + 360) } }
            .onChange(of: cents) { old, new in
                // New money logged: one full turn while the digits roll.
                if !reduceMotion, old != new { spin(to: angle + 360) }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: settles)
            .accessibilityLabel("This week, \(Money.format(cents: cents))")
            .accessibilityHint("Swipe sideways to spin")
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let start = dragStart ?? angle
                dragStart = start
                var transaction = Transaction()
                transaction.disablesAnimations = true // the number tracks the finger exactly
                withTransaction(transaction) { angle = start + value.translation.width * 0.9 }
            }
            .onEnded { value in
                let start = dragStart ?? angle
                dragStart = nil
                // Carry the swipe's speed, then come to rest showing a face.
                let thrown = start + max(-1440, min(1440, value.predictedEndTranslation.width * 1.6))
                spin(to: (thrown / 180).rounded() * 180)
            }
    }

    private func spin(to target: Double) {
        withAnimation(.spring(duration: 1.3, bounce: 0.22)) { angle = target }
        settles += 1
    }

    /// Debug: `-spin 60` holds the number at an angle for screenshots.
    private static var debugAngle: Double {
        #if DEBUG
        UserDefaults.standard.double(forKey: "spin")
        #else
        0
        #endif
    }
}

/// The number drawn as a stack of thin slices, each a little further back, so that turning it shows an edge.
/// `Animatable`, so every frame of a spin is drawn at its true angle and the right face is in front.
struct ExtrudedAmount: View, Animatable {
    let text: String
    let cents: Int
    /// The spin: animated, so each frame is drawn at its true angle.
    var angle: Double
    /// A small extra turn applied on top, updated every frame and never animated.
    var sway: Double = 0

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    private static let slices = 18
    private static let spacing: CGFloat = 1.4

    var body: some View {
        let turned = angle + sway
        let radians = turned * .pi / 180
        let frontFacing = cos(radians) >= 0
        ZStack(alignment: .leading) {
            ForEach(0..<Self.slices, id: \.self) { index in
                slice(index, mirrored: !frontFacing)
                    .rotation3DEffect(.degrees(turned), axis: (x: 0, y: 1, z: 0), anchor: .center,
                                      anchorZ: (CGFloat(index) - CGFloat(Self.slices - 1) / 2) * Self.spacing,
                                      perspective: 0.5)
                    .zIndex(frontFacing ? Double(Self.slices - index) : Double(index))
            }
        }
        // A little darker as it turns away from the light.
        .brightness(-0.16 * abs(sin(radians)))
        // The shadow it casts on the page narrows as it turns edge-on.
        .background(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.22))
                .frame(height: 12)
                .scaleEffect(x: 0.35 + 0.6 * abs(cos(radians)))
                .blur(radius: 7)
                .offset(y: 8)
        }
    }

    @ViewBuilder
    private func slice(_ index: Int, mirrored: Bool) -> some View {
        let isFront = index == 0, isBack = index == Self.slices - 1
        Text(text)
            .font(Theme.display(68))
            .foregroundStyle(isFront ? Theme.ink : isBack ? Theme.brand : (index % 2 == 0 ? Theme.brandEdge : Theme.brand))
            .contentTransition(.numericText(value: Double(cents)))
            .animation(Motion.move, value: cents)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            // Seen from behind, the whole stack is written mirrored so the back face reads correctly.
            // The swap happens edge-on, where the number has no width, so it is never visible.
            .scaleEffect(x: mirrored ? -1 : 1)
            .accessibilityHidden(!isFront)
    }
}
