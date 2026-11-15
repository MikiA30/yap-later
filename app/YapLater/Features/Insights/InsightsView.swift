import SwiftUI

/// The week in pictures: spending by day, by category, and what deserves attention.
/// It slides in from the right; swipe right or tap the arrow to go back.
struct InsightsView: View {
    let insights: WeekInsights
    var onClose: () -> Void

    @State private var appeared = false
    @State private var selectedDay: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    header
                    summary
                    section("Day by day") { DayBars(days: insights.days, appeared: appeared, selected: $selectedDay) }
                    if !insights.slices.isEmpty {
                        section("Where it went") { CategoryRing(insights: insights, appeared: appeared) }
                    }
                    section("Worth a look") { tips }
                }
                .padding(.horizontal, Theme.Space.xl)
                .padding(.top, Theme.Space.s)
                .padding(.bottom, Theme.Space.xxl)
            }
            .scrollIndicators(.hidden)
        }
        .swipeBack(onClose: onClose)
        .onAppear {
            selectedDay = insights.days.first(where: \.isToday)?.id
            if reduceMotion { appeared = true } else {
                withAnimation(.spring(duration: 0.9, bounce: 0.18).delay(0.25)) { appeared = true }
            }
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Space.m) {
            BackButton(action: onClose)
            Text("Your week")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Money.format(cents: appeared ? insights.totalCents : 0))
                .font(Theme.display(56))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: Double(appeared ? insights.totalCents : 0)))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(insights.entryCount == 0
                 ? "nothing spent yet"
                 : "\(insights.entryCount) \(insights.entryCount == 1 ? "yap" : "yaps") · about \(Money.format(cents: insights.averagePerDayCents)) a day")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text(title).font(Theme.title).foregroundStyle(Theme.ink)
            content()
        }
    }

    private var tips: some View {
        VStack(spacing: Theme.Space.m) {
            ForEach(Array(insights.tips.enumerated()), id: \.element.id) { index, tip in
                HStack(alignment: .top, spacing: Theme.Space.m) {
                    Image(systemName: tip.symbol)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(color(for: tip.tone), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title).font(Theme.headline).foregroundStyle(Theme.ink)
                        Text(tip.detail).font(Theme.caption).foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Theme.Space.m)
                .stickerCard(edge: color(for: tip.tone).opacity(tip.tone == .neutral ? 0.25 : 0.9))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 18)
                .animation(Motion.present.delay(0.3 + Motion.stagger(index, step: 0.07)), value: appeared)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func color(for tone: WeekInsights.Tip.Tone) -> Color {
        switch tone {
        case .good: Theme.color(for: .groceries)
        case .watch: Theme.warning
        case .alert: Theme.danger
        case .neutral: Theme.color(for: .bills)
        }
    }
}

/// Seven chunky columns, one per day. They grow into place one after another; tap one to read its amount.
struct DayBars: View {
    let days: [WeekInsights.Day]
    let appeared: Bool
    @Binding var selected: Int?
    private let height: CGFloat = 150

    var body: some View {
        let peak = max(days.map(\.cents).max() ?? 0, 1)
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack(alignment: .bottom, spacing: Theme.Space.s) {
                ForEach(days) { day in
                    let isSelected = selected == day.id
                    let full = max(CGFloat(day.cents) / CGFloat(peak) * height, 8)
                    VStack(spacing: Theme.Space.s) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(fill(day, isSelected))
                            .frame(height: appeared ? full : 8)
                            // The solid side that makes each column a block rather than a stripe.
                            .background(edge(day, isSelected),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous).offset(x: 3, y: 4))
                            .scaleEffect(isSelected ? 1.06 : 1, anchor: .bottom)
                            .animation(Motion.present.delay(Motion.stagger(day.id, step: 0.07, cap: 7)), value: appeared)
                        Text(day.label)
                            .font(Theme.label)
                            .foregroundStyle(day.isToday ? Theme.brand : Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: height + 26)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(Motion.quick) { selected = day.id } }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.label): \(Money.format(cents: day.cents))\(day.isToday ? ", today" : "")")
                }
            }
            if let day = days.first(where: { $0.id == selected }) {
                Text(day.isFuture ? "Still to come" : "\(Money.format(cents: day.cents)) \(day.isToday ? "today" : "that day")")
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText(value: Double(day.cents)))
            }
        }
        .padding(Theme.Space.l)
        .stickerCard()
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func fill(_ day: WeekInsights.Day, _ isSelected: Bool) -> Color {
        if day.cents == 0 { return Theme.ink.opacity(0.10) }
        return isSelected || day.isToday ? Theme.brand : Theme.ink.opacity(0.82)
    }

    private func edge(_ day: WeekInsights.Day, _ isSelected: Bool) -> Color {
        if day.cents == 0 { return .clear }
        return isSelected || day.isToday ? Theme.brandEdge : Theme.edge.opacity(0.35)
    }
}

/// Spending by category as a thick ring that sweeps open. Drag it and it tilts toward your finger.
struct CategoryRing: View {
    let insights: WeekInsights
    let appeared: Bool
    @GestureState private var pull: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let thickness: CGFloat = 30

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            ZStack {
                // The underside, a few points lower, gives the ring its thickness.
                ring(darkened: true).offset(y: 7)
                ring(darkened: false)
                if let top = insights.slices.first {
                    VStack(spacing: 0) {
                        Text(top.category.displayName).font(Theme.caption).foregroundStyle(Theme.inkSoft)
                        Text("\(Int((top.share * 100).rounded()))%").font(Theme.display(34)).foregroundStyle(Theme.ink)
                    }
                    .opacity(appeared ? 1 : 0)
                }
            }
            .frame(width: 210, height: 210)
            .padding(.top, Theme.Space.s)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : Double(-pull.height) / 5), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : Double(pull.width) / 5), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .animation(.spring(duration: 0.6, bounce: 0.35), value: pull)
            .gesture(DragGesture(minimumDistance: 4).updating($pull) { value, state, _ in
                state = CGSize(width: max(-160, min(160, value.translation.width)),
                               height: max(-160, min(160, value.translation.height)))
            })
            .frame(maxWidth: .infinity)

            VStack(spacing: Theme.Space.m) {
                ForEach(Array(insights.slices.enumerated()), id: \.element.id) { index, slice in
                    HStack(spacing: Theme.Space.m) {
                        CategoryBadge(category: slice.category, size: 34)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(slice.category.displayName).font(Theme.headline).foregroundStyle(Theme.ink)
                                Spacer()
                                Text(Money.format(cents: slice.cents)).font(Theme.headline).foregroundStyle(Theme.ink)
                            }
                            BudgetBar(fraction: appeared ? slice.share : 0, tint: Theme.color(for: slice.category))
                                .frame(height: 8)
                                .animation(Motion.present.delay(0.2 + Motion.stagger(index, step: 0.06)), value: appeared)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(slice.category.displayName): \(Money.format(cents: slice.cents)), \(Int((slice.share * 100).rounded())) percent")
                }
            }
        }
        .padding(Theme.Space.l)
        .stickerCard()
    }

    private func ring(darkened: Bool) -> some View {
        ZStack {
            Circle().stroke(Theme.ink.opacity(darkened ? 0 : 0.07), lineWidth: thickness)
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                Circle()
                    .trim(from: appeared ? segment.start : 0, to: appeared ? segment.end : 0)
                    .stroke(Theme.color(for: segment.category), style: StrokeStyle(lineWidth: thickness, lineCap: .butt))
                    .brightness(darkened ? -0.28 : 0)
            }
        }
        .rotationEffect(.degrees(-90))
        .padding(thickness / 2)
    }

    /// Start and end of each slice around the ring, 0...1, with a hairline gap between slices.
    private var segments: [(category: Category, start: CGFloat, end: CGFloat)] {
        var result: [(Category, CGFloat, CGFloat)] = []
        var cursor: CGFloat = 0
        let gap: CGFloat = insights.slices.count > 1 ? 0.006 : 0
        for slice in insights.slices {
            let end = cursor + CGFloat(slice.share)
            result.append((slice.category, cursor + gap, max(cursor + gap, end - gap)))
            cursor = end
        }
        return result
    }
}
