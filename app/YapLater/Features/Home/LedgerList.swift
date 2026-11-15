import SwiftUI

/// This week's entries, grouped by day, newest first.
struct LedgerList: View {
    let entries: [Entry]
    var newestID: UUID?
    var onTap: (Entry) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var days: [(day: Date, entries: [Entry])] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .map { (day: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Yaps").font(Theme.title).foregroundStyle(Theme.ink)
                .padding(.horizontal, Theme.Space.xl)

            if entries.isEmpty {
                VStack(spacing: Theme.Space.s) {
                    Image(systemName: "waveform")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(Theme.brand)
                    Text("Hold the button and say\n“spent twelve bucks on lunch”")
                        .font(Theme.body)
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Space.xxl)
            } else {
                ForEach(days, id: \.day) { group in
                    Text(Self.title(for: group.day))
                        .font(Theme.label)
                        .kerning(1.2)
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.horizontal, Theme.Space.xl)
                        .padding(.top, Theme.Space.xs)
                    ForEach(group.entries) { entry in
                        Button { onTap(entry) } label: {
                            EntryRow(entry: entry, isNew: entry.id == newestID)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.Space.l)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .scale(scale: 0.6, anchor: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.7).combined(with: .opacity)))
                    }
                }
            }
        }
        .animation(Motion.present, value: entries)
    }

    static func title(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "TODAY" }
        if calendar.isDateInYesterday(day) { return "YESTERDAY" }
        return day.formatted(.dateTime.weekday(.wide)).uppercased()
    }
}

struct EntryRow: View {
    let entry: Entry
    var isNew = false

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            CategoryBadge(category: entry.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.merchant ?? entry.category.displayName)
                    .font(Theme.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(entry.merchant == nil ? entry.date.formatted(date: .omitted, time: .shortened)
                     : "\(entry.category.displayName) · \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: Theme.Space.s)
            Text(Money.format(cents: entry.amountCents))
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
        }
        .padding(Theme.Space.m)
        .stickerCard(edge: isNew ? Theme.color(for: entry.category) : Theme.edge.opacity(0.14))
        .animation(Motion.move, value: isNew)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit")
    }
}
