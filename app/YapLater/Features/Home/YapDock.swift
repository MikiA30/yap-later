import SwiftUI

/// The bottom of the screen: what the app is hearing or saying, and the hold-to-talk button.
struct YapDock: View {
    @Bindable var model: AppModel
    @State private var levels: [Float] = Array(repeating: 0, count: 30)
    @State private var typing = false
    @State private var typedText = ""
    @FocusState private var typingFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            status
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Theme.Space.l)
                .animation(Motion.present, value: model.phase)
                .animation(Motion.present, value: model.lastSaved)
                .animation(Motion.present, value: model.pendingReminder)
                .animation(Motion.present, value: model.savedReminder)

            HStack {
                sideButton(systemImage: typing ? "keyboard.chevron.compact.down" : "keyboard",
                           label: typing ? "Hide keyboard" : "Type instead") {
                    typing.toggle()
                    typingFocused = typing
                }
                Spacer()
                YapButton(phase: model.phase, onPress: { model.beginYap() }, onRelease: { model.endYap() })
                Spacer()
                sideButton(systemImage: "xmark", label: "Cancel") { model.cancelYap() }
                    .opacity(model.isBusy ? 1 : 0)
                    .disabled(!model.isBusy)
            }
            .padding(.horizontal, Theme.Space.xxl)
        }
        .padding(.top, Theme.Space.xl)
        .padding(.bottom, Theme.Space.s)
        .background(
            LinearGradient(stops: [.init(color: Theme.paper.opacity(0), location: 0),
                                   .init(color: Theme.paper, location: 0.28)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onChange(of: model.audioLevel) { _, level in
            levels.removeFirst()
            levels.append(level)
        }
        .onChange(of: model.phase) { _, phase in
            if phase != .listening { levels = Array(repeating: 0, count: levels.count) }
        }
    }

    // MARK: Status area

    @ViewBuilder
    private var status: some View {
        if typing {
            HStack(spacing: Theme.Space.s) {
                TextField("spent 12 on lunch", text: $typedText)
                    .font(Theme.body)
                    .focused($typingFocused)
                    .submitLabel(.send)
                    .onSubmit(sendTyped)
                    .padding(Theme.Space.m)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Button("Send", systemImage: "arrow.up", action: sendTyped)
                    .labelStyle(.iconOnly)
                    .buttonStyle(ChunkyButtonStyle(radius: 16))
                    .disabled(typedText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .transition(.opacity)
        } else {
            switch model.phase {
            case .listening:
                VStack(spacing: Theme.Space.s) {
                    Waveform(levels: levels)
                        .frame(height: 56)
                    Text("Listening… let go, or tap the button, when you're done")
                        .font(Theme.caption).foregroundStyle(Theme.inkSoft)
                }
                .transition(.opacity)
            case .transcribing:
                working("Writing down what you said")
            case .thinking:
                VStack(spacing: Theme.Space.s) {
                    Text("“\(model.transcript)”")
                        .font(Theme.title)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                    working("Working it out on this phone")
                }
                .padding(Theme.Space.l)
                .frame(maxWidth: .infinity)
                .stickerCard()
                .transition(bubbleTransition)
            case .asking(let question):
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text(question)
                        .font(Theme.display(26))
                        .foregroundStyle(Theme.onBrand)
                    Text("Hold the button to answer")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.onBrand.opacity(0.85))
                }
                .padding(Theme.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .stickerCard(fill: Theme.brand, edge: Theme.brandEdge)
                .transition(bubbleTransition)
                .accessibilityElement(children: .combine)
            case .failed(let message):
                HStack(alignment: .top, spacing: Theme.Space.m) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Theme.danger)
                    Text(message).font(Theme.body).foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    Button("Dismiss", systemImage: "xmark") { model.dismissFailure() }
                        .labelStyle(.iconOnly)
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(Theme.Space.l)
                .stickerCard()
                .transition(bubbleTransition)
            case .idle:
                if let draft = model.pendingReminder {
                    ReminderCard(draft: draft, saving: model.isSavingReminder,
                                 onSave: { model.confirmReminder() }, onCancel: { model.cancelReminder() })
                        .transition(bubbleTransition)
                        .id(draft.id)
                } else if let saved = model.savedReminder {
                    HStack(spacing: Theme.Space.m) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 22, weight: .heavy)).foregroundStyle(Theme.brand)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Saved to Reminders").font(Theme.caption).foregroundStyle(Theme.inkSoft)
                            Text("\(saved.title) · \(saved.whenText())").font(Theme.headline).foregroundStyle(Theme.ink)
                        }
                        Spacer(minLength: 0)
                        Button("Dismiss", systemImage: "xmark") { model.dismissSavedReminder() }
                            .labelStyle(.iconOnly).font(Theme.caption).foregroundStyle(Theme.inkSoft)
                    }
                    .padding(Theme.Space.l)
                    .stickerCard(edge: Theme.brand)
                    .transition(bubbleTransition)
                    .accessibilityElement(children: .combine)
                } else if let saved = model.lastSaved {
                    SavedToast(entry: saved, group: model.lastSavedGroup) { model.undoLast() }
                        .transition(bubbleTransition)
                        .id(saved.id)
                } else {
                    Text("Hold to yap")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                        .transition(.opacity)
                }
            }
        }
    }

    private var bubbleTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.85, anchor: .bottom).combined(with: .opacity)
    }

    private func working(_ text: String) -> some View {
        HStack(spacing: Theme.Space.s) {
            ProgressView().tint(Theme.brand)
            Text(text).font(Theme.caption).foregroundStyle(Theme.inkSoft)
        }
    }

    private func sideButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(label, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(Theme.ink)
            .frame(width: 52, height: 52)
            .background(Theme.card, in: Circle())
            .background(Theme.edge.opacity(0.14), in: Circle().offset(y: 3))
    }

    private func sendTyped() {
        let text = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        typedText = ""
        typing = false
        typingFocused = false
        model.submit(text: text)
    }
}

/// The big hold-to-talk button. Sinks onto its edge while held.
struct YapButton: View {
    let phase: AppModel.Phase
    var onPress: () -> Void
    var onRelease: () -> Void
    @State private var held = false

    private var listening: Bool { phase == .listening }
    private var waiting: Bool { phase == .transcribing || phase == .thinking }

    var body: some View {
        let size: CGFloat = 104
        ZStack {
            Circle().fill(waiting ? Theme.inkSoft.opacity(0.5) : Theme.brandEdge)
                .offset(y: Theme.depth + 2)
            Circle().fill(waiting ? Theme.inkSoft : Theme.brand)
                .offset(y: held ? Theme.depth + 2 : 0)
            Image(systemName: listening ? "waveform" : "mic.fill")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(Theme.onBrand)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.variableColor.iterative, isActive: listening)
                .offset(y: held ? Theme.depth + 2 : 0)
        }
        .frame(width: size, height: size)
        .scaleEffect(listening ? 1.08 : 1)
        .animation(Motion.quick, value: held)
        .animation(Motion.present, value: listening)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !held else { return }
                    held = true
                    // Already listening (started by the Action Button): this press just ends it on release.
                    if !listening { onPress() }
                }
                .onEnded { _ in
                    held = false
                    onRelease()
                }
        )
        .sensoryFeedback(.impact(weight: .heavy), trigger: held)
        .accessibilityLabel("Yap")
        .accessibilityHint("Hold to talk, let go when you're done")
        .accessibilityAddTraits(.isButton)
    }
}

/// Bars that follow the microphone level while listening.
struct Waveform: View {
    let levels: [Float]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(Theme.brand)
                    .frame(width: 5, height: 6 + CGFloat(level) * 50)
            }
        }
        .animation(.smooth(duration: 0.12), value: levels)
        .accessibilityHidden(true)
    }
}

/// A reminder the app understood, waiting for an explicit Save. Shows exactly what will be created.
struct ReminderCard: View {
    let draft: ReminderDraft
    var saving = false
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack(alignment: .top, spacing: Theme.Space.m) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.brand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("REMINDER").font(Theme.label).kerning(1.2).foregroundStyle(Theme.inkSoft)
                    Text(draft.title).font(Theme.display(24)).foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(draft.whenText() + (draft.amountCents.map { " · \(Money.format(cents: $0))" } ?? ""))
                        .font(Theme.headline).foregroundStyle(Theme.brand)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: Theme.Space.m) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(ChunkyButtonStyle(fill: Theme.ink.opacity(0.1), edge: Theme.edge.opacity(0.12),
                                                   foreground: Theme.ink, radius: 14))
                Spacer()
                Button(saving ? "Saving…" : "Save to Reminders", systemImage: "checkmark", action: onSave)
                    .buttonStyle(ChunkyButtonStyle(radius: 14))
                    .disabled(saving)
            }
        }
        .padding(Theme.Space.l)
        .stickerCard(edge: Theme.brand)
        .accessibilityElement(children: .contain)
    }
}

/// Confirms what was just saved and offers Undo for a few seconds.
struct SavedToast: View {
    let entry: Entry
    /// All entries the yap saved; more than one after a ramble.
    var group: [Entry] = []
    var onUndo: () -> Void

    private var isGroup: Bool { group.count > 1 }
    private var totalCents: Int { isGroup ? group.reduce(0) { $0 + $1.amountCents } : entry.amountCents }

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            CategoryBadge(category: entry.category, size: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(isGroup ? "Saved \(group.count) expenses" : "Saved to \(entry.category.displayName)")
                    .font(Theme.caption).foregroundStyle(Theme.inkSoft)
                Text(Money.format(cents: totalCents))
                    .font(Theme.display(24)).foregroundStyle(Theme.ink)
            }
            Spacer(minLength: 0)
            Button("Undo", systemImage: "arrow.uturn.backward", action: onUndo)
                .buttonStyle(ChunkyButtonStyle(fill: Theme.ink, edge: Theme.edge.opacity(0.5),
                                               foreground: Theme.paper, radius: 14))
        }
        .padding(Theme.Space.m)
        .stickerCard(edge: Theme.color(for: entry.category))
        .accessibilityElement(children: .contain)
    }
}
