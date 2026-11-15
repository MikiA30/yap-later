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
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(spacing: Theme.Space.m) {
                            ForEach(statuses) { status in
                                BudgetCard(status: status, highlighted: highlighted == status.category)
                                    .id(status.category)
                            }
                        }
                        .padding(.horizontal, Theme.Space.l)
                        .padding(.bottom, 2)
                    }
                    .scrollIndicators(.hidden)
                    .scrollClipDisabled() // a card that steps forward is not cut off
                    .onChange(of: statuses) { old, new in
                        // Bring the budget that just took a hit into view before it plays.
                        guard let hit = new.first(where: { status in
                            old.first { $0.category == status.category }.map { status.spentCents > $0.spentCents } ?? false
                        }) else { return }
                        withAnimation(Motion.move) { proxy.scrollTo(hit.category, anchor: .center) }
                    }
                }
            }
        }
    }
}

struct BudgetCard: View {
    let status: BudgetStatus
    var highlighted = false
    /// What is drawn. It trails `status` while the card plays "money just went out":
    /// step forward, fill the bar to the new amount, step back.
    @State private var shown: BudgetStatus?
    @State private var spotlit = false
    @State private var run = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: BudgetStatus { shown ?? status }
    private var level: Nudge.Level { BudgetMath.level(of: current) }
    private var tint: Color {
        switch level {
        case .fine: Theme.color(for: current.category)
        case .low: Theme.warning
        case .spent, .over: Theme.danger
        }
    }

    private var headline: String {
        current.remainingCents >= 0
            ? "\(Money.format(cents: current.remainingCents)) left"
            : "\(Money.format(cents: -current.remainingCents)) over"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack(spacing: Theme.Space.s) {
                CategoryBadge(category: current.category, size: 34)
                Text(current.category.displayName)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Text(headline)
                .font(Theme.display(24))
                .foregroundStyle(level >= .low ? tint : Theme.ink)
                .contentTransition(.numericText(value: Double(current.remainingCents)))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            BudgetBar(fraction: current.fractionUsed, tint: tint)
            Text("of \(Money.format(cents: current.limitCents)) a week")
                .font(Theme.label)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(Theme.Space.l)
        .frame(width: 168, alignment: .leading)
        .stickerCard(edge: highlighted || spotlit ? tint : Theme.edge.opacity(0.14))
        .scaleEffect(spotlit ? 1.2 : (highlighted ? 1.04 : 1))
        .shadow(color: .black.opacity(spotlit ? 0.28 : 0), radius: 18, y: 12)
        .zIndex(spotlit ? 2 : 0)
        .animation(Motion.delight, value: highlighted)
        .onAppear { shown = status }
        .onChange(of: status) { old, new in play(from: old, to: new) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(status.category.displayName) budget: \(headline) of \(Money.format(cents: status.limitCents)) a week")
    }

    private func play(from old: BudgetStatus, to new: BudgetStatus) {
        run += 1
        let mine = run
        // Only new spending gets the full moment; edits, undo, and limit changes just update.
        guard !reduceMotion, new.spentCents > old.spentCents, new.limitCents == old.limitCents else {
            withAnimation(Motion.move) {
                shown = new
                spotlit = false
            }
            return
        }
        shown = old
        withAnimation(Motion.present) { spotlit = true } completion: {
            guard mine == run else { return }
            withAnimation(.smooth(duration: 0.9)) { shown = new } completion: {
                guard mine == run else { return }
                withAnimation(Motion.move.delay(0.4)) { spotlit = false }
            }
        }
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
    }
}
