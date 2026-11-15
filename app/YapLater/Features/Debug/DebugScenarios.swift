#if DEBUG
import Foundation

/// Puts the app into a known visual state for screenshots and UI work.
/// Launch with `-scenario <name>`; the app then runs on mocks with an in-memory store (labeled MOCK).
@MainActor
enum DebugScenarios {
    /// Seed data for the scenario's in-memory store.
    static func seed(for name: String) -> (entries: [Entry], budgets: [Budget]) {
        switch name {
        case "empty":
            return ([], [])
        default:
            let now = Date.now
            return ([
                Entry(amountCents: 6_200, merchant: "Trader Joe's", category: .groceries,
                      date: now.addingTimeInterval(-3_600), transcript: "sixty two at Trader Joe's"),
                Entry(amountCents: 3_800, merchant: "Walmart", category: .groceries,
                      date: now.addingTimeInterval(-7_200), transcript: "thirty eight at Walmart"),
                Entry(amountCents: 650, merchant: nil, category: .coffee,
                      date: now.addingTimeInterval(-9_000), transcript: "coffee six fifty"),
                Entry(amountCents: 2_200, merchant: "Uber", category: .transport,
                      date: now.addingTimeInterval(-12_000), transcript: "twenty two on an Uber"),
            ], [
                Budget(category: .groceries, weeklyLimitCents: 20_000),
                Budget(category: .coffee, weeklyLimitCents: 2_500),
                Budget(category: .fun, weeklyLimitCents: 4_000),
            ])
        }
    }

    /// Drives the model into the named state after launch.
    static func run(_ name: String, model: AppModel) async {
        switch name {
        case "listening":
            model.beginYap()
        case "nudge":
            model.submit(text: "Just spent fifty bucks on groceries at Walmart")
        case "asking":
            model.submit(text: "Grabbed a coffee")
        case "failed":
            model.submit(text: "What's the weather like")
        default:
            break
        }
    }
}
#endif
