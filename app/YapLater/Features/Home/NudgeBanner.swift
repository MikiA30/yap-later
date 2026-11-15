import SwiftUI

/// A loud heads-up that a weekly budget is running low, used up, or exceeded.
struct NudgeBanner: View {
    let nudge: Nudge
    var onDismiss: () -> Void

    private var urgent: Bool { nudge.level >= .spent }
    private var fill: Color { urgent ? Theme.danger : Theme.lemon }
    private var text: Color { urgent ? .white : .black }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Image(systemName: nudge.level >= .spent ? "flame.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(text)
                .symbolEffect(.bounce, value: nudge.id)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(nudge.level >= .spent ? "BUDGET BLOWN" : "HEADS UP")
                    .font(Theme.label).kerning(1.2)
                    .foregroundStyle(text.opacity(0.7))
                Text(nudge.message)
                    .font(Theme.display(22))
                    .foregroundStyle(text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .labelStyle(.iconOnly)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(text)
                .frame(width: 32, height: 32)
                .background(text.opacity(0.14), in: Circle())
        }
        .padding(Theme.Space.l)
        .stickerCard(fill: fill, edge: Theme.edge.opacity(0.35))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
