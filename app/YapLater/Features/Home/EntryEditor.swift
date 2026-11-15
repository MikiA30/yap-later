import SwiftUI

/// Fix anything the app got wrong about one entry, or delete it.
struct EntryEditor: View {
    @State var entry: Entry
    var onSave: (Entry) -> Void
    var onDelete: () -> Void
    @State private var amountText = ""
    @Environment(\.dismiss) private var dismiss

    private var cents: Int? {
        guard let value = Double(amountText.replacingOccurrences(of: ",", with: ".")), value > 0 else { return nil }
        return Int((value * 100).rounded())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$").font(Theme.display(34)).foregroundStyle(Theme.inkSoft)
                    TextField("0", text: $amountText)
                        .font(Theme.display(56))
                        .foregroundStyle(Theme.ink)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .accessibilityLabel("Amount in dollars")
                }

                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("CATEGORY").font(Theme.label).kerning(1.2).foregroundStyle(Theme.inkSoft)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: Theme.Space.s)], spacing: Theme.Space.s) {
                        ForEach(Category.allCases) { category in
                            let selected = entry.category == category
                            Button {
                                entry.category = category
                            } label: {
                                Label(category.displayName, systemImage: category.symbol)
                                    .font(Theme.caption)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.Space.m)
                                    .foregroundStyle(selected ? .white : Theme.ink)
                                    .background(selected ? Theme.color(for: category) : Theme.ink.opacity(0.07),
                                                in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    .animation(Motion.quick, value: entry.category)
                }

                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Text("WHERE").font(Theme.label).kerning(1.2).foregroundStyle(Theme.inkSoft)
                    TextField("Shop or place (optional)", text: Binding(
                        get: { entry.merchant ?? "" },
                        set: { entry.merchant = $0.isEmpty ? nil : $0 }))
                        .font(Theme.body)
                        .padding(Theme.Space.m)
                        .background(Theme.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                }

                if !entry.transcript.isEmpty {
                    Text("You said: “\(entry.transcript)”")
                        .font(Theme.caption).foregroundStyle(Theme.inkSoft)
                }

                HStack(spacing: Theme.Space.m) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        onDelete()
                        dismiss()
                    }
                    .buttonStyle(ChunkyButtonStyle(fill: Theme.danger, edge: Theme.edge.opacity(0.45)))
                    Spacer()
                    Button("Save") {
                        if let cents { entry.amountCents = cents }
                        onSave(entry)
                        dismiss()
                    }
                    .buttonStyle(ChunkyButtonStyle())
                    .disabled(cents == nil)
                }
            }
            .padding(Theme.Space.xl)
        }
        .background(Theme.paper)
        .onAppear {
            amountText = String(format: entry.amountCents % 100 == 0 ? "%.0f" : "%.2f", Double(entry.amountCents) / 100)
        }
    }
}
