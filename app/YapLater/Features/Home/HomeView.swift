import SwiftUI

/// The whole app on one screen: this week's total, budgets, the ledger, and the yap button.
struct HomeView: View {
    @Bindable var model: AppModel
    @State private var editing: Entry?
    @State private var showingBudgets = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    header
                    hero
                    BudgetStrip(statuses: model.budgetStatuses, highlighted: model.lastBudgetSet?.category) {
                        showingBudgets = true
                    }
                    LedgerList(entries: model.entries, newestID: model.lastSaved?.id) { editing = $0 }
                }
                .padding(.top, Theme.Space.s)
                .padding(.bottom, 260) // room for the dock
            }
            .scrollIndicators(.hidden)

            YapDock(model: model)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            // Pinned above the content, which slides down to make room: the total stays visible.
            if let nudge = model.nudge {
                NudgeBanner(nudge: nudge) { model.dismissNudge() }
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, Theme.Space.s)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .id(nudge.id)
            }
        }
        .animation(Motion.present, value: model.nudge)
        .sensoryFeedback(.warning, trigger: model.nudge?.id) { _, new in new != nil }
        .sensoryFeedback(.success, trigger: model.lastSaved?.id) { _, new in new != nil }
        .sheet(item: $editing) { entry in
            EntryEditor(entry: entry) { model.update($0) } onDelete: { model.delete(entry) }
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingBudgets) {
            BudgetEditor(model: model)
                .presentationDetents([.large])
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Space.s) {
            Text("yap later")
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Spacer()
            if model.usesMocks {
                Chip(text: "MOCK", fill: Theme.lemon, foreground: .black)
                    .accessibilityLabel("Mock mode. Speech or the model is a stand-in.")
            } else {
                Chip(text: "On this phone", systemImage: "lock.fill")
                    .accessibilityLabel("Everything runs on this phone. Model: \(model.interpreterName)")
            }
        }
        .padding(.horizontal, Theme.Space.xl)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THIS WEEK")
                .font(Theme.label)
                .kerning(1.2)
                .foregroundStyle(Theme.inkSoft)
            Text(Money.format(cents: model.weekTotalCents))
                .font(Theme.display(68))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: Double(model.weekTotalCents)))
                .animation(Motion.move, value: model.weekTotalCents)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(model.entries.isEmpty ? "nothing spent yet" : "spent across ^[\(model.entries.count) yap](inflect: true)")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.Space.xl)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView(model: AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(),
                             store: InMemoryLedgerStore(), speaker: SilentSpeaker()))
}
