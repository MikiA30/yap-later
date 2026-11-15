import SwiftUI

/// A chunky button that sits on a solid edge and sinks when pressed.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = Theme.brand
    var edge: Color = Theme.brandEdge
    var foreground: Color = Theme.onBrand
    var radius: CGFloat = 18

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(Theme.headline)
            .foregroundStyle(foreground)
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.m)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .offset(y: pressed ? Theme.depth : 0)
            .background(edge, in: RoundedRectangle(cornerRadius: radius, style: .continuous).offset(y: Theme.depth))
            .padding(.bottom, Theme.depth)
            .animation(Motion.quick, value: pressed)
    }
}

/// A card that sits on a solid edge, like a sticker on paper.
struct StickerCard: ViewModifier {
    var fill: Color = Theme.card
    var edge: Color = Theme.edge.opacity(0.14)
    var radius: CGFloat = Theme.Radius.card

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .background(edge, in: RoundedRectangle(cornerRadius: radius, style: .continuous).offset(y: 4))
            .padding(.bottom, 4)
    }
}

extension View {
    func stickerCard(fill: Color = Theme.card, edge: Color = Theme.edge.opacity(0.14),
                     radius: CGFloat = Theme.Radius.card) -> some View {
        modifier(StickerCard(fill: fill, edge: edge, radius: radius))
    }
}

/// The category's symbol on its color.
struct CategoryBadge: View {
    let category: Category
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.42, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.color(for: category), in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A small rounded label, e.g. MOCK or the model name.
struct Chip: View {
    let text: String
    var systemImage: String?
    var fill: Color = Theme.ink.opacity(0.08)
    var foreground: Color = Theme.ink

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(Theme.label)
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(fill, in: Capsule())
    }
}
