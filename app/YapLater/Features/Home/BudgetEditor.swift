import SwiftUI

/// Set, change, or remove the weekly limit for each category.
struct BudgetEditor: View {
    @Bindable var model: AppModel
    @State private var amounts: [Category: String] = [:]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.m) {
                    Text("How much do you want to spend each week? Leave a box empty for no budget.")
                        .font(Theme.body).foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(Category.allCases) { category in
                        HStack(spacing: Theme.Space.m) {
                            CategoryBadge(category: category, size: 40)
                            Text(category.displayName).font(Theme.headline).foregroundStyle(Theme.ink)
                            Spacer()
                            Text("$").font(Theme.headline).foregroundStyle(Theme.inkSoft)
                            TextField("—", text: Binding(get: { amounts[category] ?? "" },
                                                         set: { amounts[category] = $0.filter(\.isNumber) }))
                                .font(Theme.display(22))
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                #endif
                                .multilineTextAlignment(.trailing)
                                .frame(width: 84)
                                .accessibilityLabel("\(category.displayName) weekly budget in dollars")
                        }
                        .padding(Theme.Space.m)
                        .stickerCard()
                    }
                }
                .padding(Theme.Space.l)
            }
            .background(Theme.paper)
            .navigationTitle("Weekly budgets")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        apply()
                        dismiss()
                    }
                    .font(Theme.headline)
                }
            }
        }
        .onAppear {
            amounts = Dictionary(uniqueKeysWithValues: model.budgetStatuses.map { ($0.category, String($0.limitCents / 100)) })
        }
    }

    private func apply() {
        let existing = Set(model.budgetStatuses.map(\.category))
        for category in Category.allCases {
            if let dollars = Int(amounts[category] ?? ""), dollars > 0 {
                model.setBudget(category: category, weeklyLimitCents: dollars * 100)
            } else if existing.contains(category) {
                model.removeBudget(category: category)
            }
        }
    }
}
