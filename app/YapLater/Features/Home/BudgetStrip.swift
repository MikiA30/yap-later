import SwiftUI

/// A sideways row of weekly budgets, each showing what is left.
struct BudgetStrip: View {
    let statuses: [BudgetStatus]
    var highlighted: Category?
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack {
                Text("Budgets").font(Theme.title).foregroundStyle(Theme.ink)
                Spacer()
                Button(statuses.isEmpty ? "Add" : "Edit", systemImage: statuses.isEmpty ? "plus" : "slider.horizontal.3", action: onEdit)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.brand)
            }
            .padding(.horizontal, Theme.Space.xl)

            if statuses.isEmpty {
                Button(action: onEdit) {
                    HStack(spacing: Theme.Space.m) {
                        Image(systemName: "target").font(.system(size: 22, weight: .heavy)).foregroundStyle(Theme.brand)
                        Text("Say “set my coffee budget to 25 a week”, or tap to add one.")
                            .font(Theme.body).foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(Theme.Space.l)
                    .stickerCard()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Space.l)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: Theme.Space.m) {
                        ForEach(statuses) { status in
                            BudgetCard(status: status, highlighted: highlighted == status.category)
                        }
                    }
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.bottom, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct BudgetCard: View {
    let status: BudgetStatus
    var highlighted = false

    private var level: Nudge.Level { BudgetMath.level(of: status) }
    private var tint: Color {
        switch level {
        case .fine: Theme.color(for: status.category)
        case .low: Theme.warning
        case .spent, .over: Theme.danger
        }
    }

    private var headline: String {
        status.remainingCents >= 0
            ? "\(Money.format(cents: status.remainingCents)) left"
            : "\(Money.format(cents: -status.remainingCents)) over"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(spacing: Theme.Space.s) {
                CategoryBadge(category: status.category, size: 34)
                Text(status.category.displayName)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Text(headline)
                .font(Theme.display(24))
                .foregroundStyle(level >= .low ? tint : Theme.ink)
                .contentTransition(.numericText(value: Double(status.remainingCents)))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            BudgetBar(fraction: status.fractionUsed, tint: tint)
            Text("of \(Money.format(cents: status.limitCents)) a week")
                .font(Theme.label)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(Theme.Space.l)
        .frame(width: 168, alignment: .leading)
        .stickerCard(edge: highlighted ? tint : Theme.edge.opacity(0.14))
        .scaleEffect(highlighted ? 1.04 : 1)
        .animation(Motion.move, value: status)
        .animation(Motion.delight, value: highlighted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(status.category.displayName) budget: \(headline) of \(Money.format(cents: status.limitCents)) a week")
    }
}

/// A thick bar that fills as the budget is used.
struct BudgetBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.08))
                Capsule().fill(tint)
                    .frame(width: max(proxy.size.height, proxy.size.width * fraction))
            }
        }
        .frame(height: 12)
        .animation(Motion.move, value: fraction)
    }
}
