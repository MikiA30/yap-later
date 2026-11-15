import SwiftUI

/// The Yap Later mark: a speech bubble with a dollar sign, on the brand color. Tap it and it wobbles.
struct LogoMark: View {
    var size: CGFloat = 36
    @State private var taps = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(Theme.brand)
            Image(systemName: "bubble.left.fill")
                .font(.system(size: size * 0.6, weight: .black))
                .foregroundStyle(Color(light: 0xFFF4E4, dark: 0xFFF4E4))
            Text("$")
                .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.brandEdge)
                .offset(y: -size * 0.04)
        }
        .frame(width: size, height: size)
        .background(Theme.brandEdge, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).offset(y: 3))
        .keyframeAnimator(initialValue: 0.0, trigger: taps) { content, angle in
            content.rotationEffect(.degrees(reduceMotion ? 0 : angle))
        } keyframes: { _ in
            SpringKeyframe(-14, duration: 0.12)
            SpringKeyframe(11, duration: 0.14)
            SpringKeyframe(-6, duration: 0.14)
            SpringKeyframe(0, duration: 0.3, spring: .bouncy)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .onTapGesture { taps += 1 }
        .accessibilityHidden(true)
    }
}

/// The mark and the name together, for the top of the home screen.
struct LogoLockup: View {
    var body: some View {
        HStack(spacing: Theme.Space.s) {
            LogoMark()
            (Text("Yap").foregroundStyle(Theme.ink) + Text("Later").foregroundStyle(Theme.brand))
                .font(Theme.display(24))
                .kerning(-0.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yap Later")
        .accessibilityAddTraits(.isHeader)
    }
}

/// Lets a page that slid in from the right be pulled back out with a sideways swipe.
struct SwipeBack: ViewModifier {
    var onClose: () -> Void
    @State private var dragX: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: dragX)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only a mostly sideways pull to the right moves the page.
                        guard value.translation.width > 0,
                              abs(value.translation.width) > abs(value.translation.height) else { return }
                        dragX = value.translation.width
                    }
                    .onEnded { value in
                        if value.translation.width > 110 || value.predictedEndTranslation.width > 260 {
                            onClose()
                        } else {
                            withAnimation(Motion.present) { dragX = 0 }
                        }
                    }
            )
    }
}

extension View {
    func swipeBack(onClose: @escaping () -> Void) -> some View { modifier(SwipeBack(onClose: onClose)) }
}

/// The round back button at the top of a page.
struct BackButton: View {
    var action: () -> Void

    var body: some View {
        Button("Back", systemImage: "chevron.left", action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(Theme.ink)
            .frame(width: 44, height: 44)
            .background(Theme.card, in: Circle())
            .background(Theme.edge.opacity(0.14), in: Circle().offset(y: 3))
            .buttonStyle(.plain)
    }
}
