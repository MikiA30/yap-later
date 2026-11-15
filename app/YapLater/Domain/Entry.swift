import Foundation

/// One logged expense. Money is integer cents, USD.
struct Entry: Identifiable, Equatable, Sendable {
    let id: UUID
    var amountCents: Int
    var merchant: String?
    var category: Category
    var date: Date
    var transcript: String

    init(id: UUID = UUID(), amountCents: Int, merchant: String? = nil,
         category: Category, date: Date = .now, transcript: String) {
        self.id = id
        self.amountCents = amountCents
        self.merchant = merchant
        self.category = category
        self.date = date
        self.transcript = transcript
    }
}

enum Money {
    static func format(cents: Int) -> String {
        let dollars = Double(cents) / 100
        return dollars.formatted(.currency(code: "USD").precision(.fractionLength(cents % 100 == 0 ? 0 : 2)))
    }
}
