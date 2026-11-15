import SwiftUI

struct YapView: View {
    @Bindable var model: YapModel

    var body: some View {
        VStack(spacing: 0) {
            header
            ledger
            status
            yapButton
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Yap Later")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                Spacer()
                if model.usesMocks {
                    Text("MOCK")
                        .font(.system(.caption, design: .rounded, weight: .heavy))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.orange, in: Capsule())
                        .foregroundStyle(.white)
                        .accessibilityLabel("Mock mode: no real speech or model")
                }
            }
            Text(Money.format(cents: model.weekTotalCents))
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .contentTransition(.numericText(value: Double(model.weekTotalCents)))
                .animation(Motion.move, value: model.weekTotalCents)
            Text("spent this week")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var ledger: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(model.entries) { entry in
                    EntryRow(entry: entry)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .animation(Motion.present, value: model.entries)
        }
        .overlay {
            if model.entries.isEmpty {
                ContentUnavailableView("Nothing yet", systemImage: "waveform",
                                       description: Text("Hold the button and say what you spent."))
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        Group {
            switch model.phase {
            case .idle:
                if model.lastAddedID != nil {
                    Button("Undo", systemImage: "arrow.uturn.backward") { model.undoLast() }
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                } else {
                    Color.clear
                }
            case .listening:
                Label("Listening…", systemImage: "waveform")
                    .symbolEffect(.variableColor.iterative, isActive: true)
            case .thinking(let transcript):
                Text("“\(transcript)”")
                    .multilineTextAlignment(.center)
            case .failed(let message):
                Text(message).foregroundStyle(.red)
            }
        }
        .font(.system(.body, design: .rounded, weight: .semibold))
        .frame(height: 56)
        .padding(.horizontal, 24)
        .animation(Motion.quick, value: model.phase)
    }

    private var yapButton: some View {
        Button {
            if model.isBusy { model.cancel() } else { model.startYap() }
        } label: {
            Image(systemName: model.isBusy ? "xmark" : "mic.fill")
                .font(.system(size: 34, weight: .heavy))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .background(model.isBusy ? Color.gray : Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 0, y: 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: model.isBusy)
        .accessibilityLabel(model.isBusy ? "Cancel" : "Yap")
        .padding(.bottom, 24)
    }
}

private struct EntryRow: View {
    let entry: Entry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.category.symbol)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.merchant ?? entry.category.displayName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text(entry.category.displayName)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.format(cents: entry.amountCents))
                .font(.system(.title3, design: .rounded, weight: .heavy))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    YapView(model: YapModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter()))
}
