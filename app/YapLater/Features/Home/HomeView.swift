import SwiftUI

/// The whole app on one screen: this week's total, budgets, the ledger, and the yap button.
struct HomeView: View {
    @Bindable var model: AppModel
    @State private var editing: Entry?
    @State private var showingBudgets = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The opening moment plays once per launch: bubbles rise, then the greeting settles in.
    @State private var showingBubbles = true
    @State private var greeted = false
    @State private var showingInsights = false
    @State private var showingProfile = false
    private var profile: ProfileStore { model.profile }
    private var pageOpen: Bool { showingInsights || showingProfile }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackdrop()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xl) {
                    header
                    if let status = model.syncStatus {
                        Label(status, systemImage: "arrow.triangle.2.circlepath")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, Theme.Space.xl)
                            .transition(.opacity)
                    }
                    if greeted {
                        greeting.transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.blurReplace))
                    }
                    hero
                    BudgetStrip(statuses: model.budgetStatuses, highlighted: model.lastBudgetSet?.category) {
                        showingBudgets = true
                    }
                    .zIndex(1) // a budget card that steps forward sits above its neighbors
                    if !model.upcomingReminders.isEmpty {
                        UpcomingList(reminders: model.upcomingReminders)
                    }
                    LedgerList(entries: model.entries, newestID: model.lastSaved?.id) { editing = $0 }
                }
                .padding(.top, Theme.Space.s)
                .padding(.bottom, 260) // room for the dock
            }
            .scrollIndicators(.hidden)
            // The home screen steps back a little as the charts slide over it.
            .offset(x: pageOpen && !reduceMotion ? -70 : 0)
            .opacity(pageOpen ? 0.4 : 1)

            YapDock(model: model) { showingInsights = true }
                .offset(x: pageOpen && !reduceMotion ? -70 : 0)

            if showingInsights {
                InsightsView(insights: model.insights) { showingInsights = false }
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .trailing))
                    .zIndex(5)
            }
            if showingProfile {
                ProfileView(profile: profile, model: model) { showingProfile = false }
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.move(edge: .trailing))
                    .zIndex(5)
            }

            if showingBubbles, !reduceMotion {
                LaunchBubbles { showingBubbles = false }
            }
        }
        .onAppear {
            guard !greeted else { return }
            #if DEBUG
            if UserDefaults.standard.bool(forKey: "insights") { showingInsights = true } // `-insights YES` for screenshots
            if UserDefaults.standard.bool(forKey: "profile") { showingProfile = true } // `-profile YES` for screenshots
            #endif
            withAnimation(Motion.present.delay(reduceMotion ? 0 : 0.35)) { greeted = true }
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
        .animation(.spring(duration: 0.55, bounce: 0.12), value: showingInsights)
        .animation(.spring(duration: 0.55, bounce: 0.12), value: showingProfile)
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
            LogoLockup()
            Spacer()
            if model.usesMocks {
                Chip(text: "MOCK", fill: Theme.lemon, foreground: .black)
                    .accessibilityLabel("Mock mode. Speech or the model is a stand-in.")
            } else {
                Chip(text: "On this \(LocalAssets.deviceName)", systemImage: "lock.fill")
                    .accessibilityLabel("Everything runs on this \(LocalAssets.deviceName). Model: \(model.interpreterName)")
            }
            Button { showingProfile = true } label: {
                Avatar(profile: profile, size: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("You: name, picture, and sync")
        }
        .padding(.horizontal, Theme.Space.xl)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THIS WEEK")
                .font(Theme.label)
                .kerning(1.2)
                .foregroundStyle(Theme.inkSoft)
            SpinningTotal(cents: model.weekTotalCents)
            Text(model.entries.isEmpty ? "nothing spent yet" : "spent across ^[\(model.entries.count) yap](inflect: true)")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.Space.xl)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(profile.firstName.map { "Hello, \($0)." } ?? "Hello.")
                .font(Theme.display(40))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.opacity)
                .foregroundStyle(Theme.ink)
            Text("\(Self.partOfDay()). Here's your week.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, Theme.Space.xl)
        .accessibilityElement(children: .combine)
    }

    static func partOfDay(at date: Date = .now, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }
}

/// Reminders this app created that are still ahead.
struct UpcomingList: View {
    let reminders: [ReminderDraft]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Coming up").font(Theme.title).foregroundStyle(Theme.ink)
                .padding(.horizontal, Theme.Space.xl)
            ForEach(reminders.prefix(4)) { reminder in
                HStack(spacing: Theme.Space.m) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(reminder.title).font(Theme.headline).foregroundStyle(Theme.ink).lineLimit(1)
                        Text(reminder.whenText()).font(Theme.caption).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer(minLength: Theme.Space.s)
                    if let cents = reminder.amountCents {
                        Text(Money.format(cents: cents)).font(Theme.display(22)).foregroundStyle(Theme.ink)
                    }
                }
                .padding(Theme.Space.m)
                .stickerCard()
                .padding(.horizontal, Theme.Space.l)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview {
    HomeView(model: AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(),
                             store: InMemoryLedgerStore(), speaker: SilentSpeaker()))
}
