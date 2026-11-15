import SwiftUI
import PhotosUI

/// "You": a picture, a name, this week at a glance, and what runs where. Nothing here leaves the device.
struct ProfileView: View {
    @Bindable var profile: ProfileStore
    @Bindable var model: AppModel
    var onClose: () -> Void

    @State private var appeared = false
    @State private var pickedPhoto: PhotosPickerItem?
    @GestureState private var pull: CGSize = .zero
    @FocusState private var editingName: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppBackdrop()
            ScrollView {
                VStack(spacing: Theme.Space.xl) {
                    HStack(spacing: Theme.Space.m) {
                        BackButton(action: onClose)
                        Text("You").font(Theme.display(30)).foregroundStyle(Theme.ink)
                        Spacer()
                    }
                    portrait
                    nameField
                    stats
                    privacyCard
                    syncCard
                }
                .padding(.horizontal, Theme.Space.xl)
                .padding(.top, Theme.Space.s)
                .padding(.bottom, Theme.Space.xxl)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .swipeBack(onClose: onClose)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    withAnimation(Motion.delight) { profile.setPhoto(data) }
                }
                pickedPhoto = nil
            }
        }
        .onAppear {
            if reduceMotion { appeared = true } else {
                withAnimation(.spring(duration: 0.8, bounce: 0.25).delay(0.22)) { appeared = true }
            }
        }
    }

    // MARK: Picture

    private var portrait: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                // A slowly turning dashed ring, like the ridged edge of a coin.
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
                    Circle()
                        .stroke(Theme.brand, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 9]))
                        .rotationEffect(.degrees(context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 30) * 12))
                }
                .frame(width: 164, height: 164)
                Avatar(profile: profile, size: 140)
                    .id(profile.photoVersion)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            PhotosPicker(selection: $pickedPhoto, matching: .images) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.paper)
                    .frame(width: 44, height: 44)
                    .background(Theme.ink.opacity(0.92), in: Circle())
                    .overlay { Circle().strokeBorder(Theme.paper, lineWidth: 3) }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(profile.photo == nil ? "Add a picture" : "Change your picture")
        }
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
        // The picture leans toward a finger dragged across it, then springs back.
        .rotation3DEffect(.degrees(reduceMotion ? 0 : Double(-pull.height) / 4), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        .rotation3DEffect(.degrees(reduceMotion ? 0 : Double(pull.width) / 4), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .animation(.spring(duration: 0.6, bounce: 0.4), value: pull)
        .gesture(DragGesture(minimumDistance: 6).updating($pull) { value, state, _ in
            state = CGSize(width: max(-140, min(140, value.translation.width)),
                           height: max(-140, min(140, value.translation.height)))
        })
        .contextMenu {
            if profile.photo != nil {
                Button("Remove picture", systemImage: "trash", role: .destructive) {
                    withAnimation(Motion.move) { profile.removePhoto() }
                }
            }
        }
        .padding(.top, Theme.Space.s)
    }

    private var nameField: some View {
        VStack(spacing: 4) {
            TextField("Your name", text: $profile.name)
                .font(Theme.display(32))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .focused($editingName)
                .submitLabel(.done)
                .onSubmit { editingName = false }
            Text(profile.name.isEmpty ? "Tap to add your name. It only changes how the app greets you."
                                      : "This is how the app greets you.")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 14)
    }

    // MARK: This week

    private var stats: some View {
        HStack(spacing: Theme.Space.m) {
            stat(value: Money.format(cents: appeared ? model.weekTotalCents : 0), number: Double(model.weekTotalCents),
                 label: "this week", index: 0)
            stat(value: "\(appeared ? model.entries.count : 0)", number: Double(model.entries.count),
                 label: model.entries.count == 1 ? "yap" : "yaps", index: 1)
            stat(value: "\(appeared ? model.budgetStatuses.count : 0)", number: Double(model.budgetStatuses.count),
                 label: model.budgetStatuses.count == 1 ? "budget" : "budgets", index: 2)
        }
    }

    private func stat(value: String, number: Double, label: String, index: Int) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.display(24))
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: appeared ? number : 0))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label).font(Theme.label).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.l)
        .padding(.horizontal, Theme.Space.s)
        .stickerCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 18)
        .animation(Motion.present.delay(0.25 + Motion.stagger(index, step: 0.07)), value: appeared)
        .accessibilityElement(children: .combine)
    }

    // MARK: What runs where

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Private by design").font(Theme.title).foregroundStyle(Theme.ink)
            fact("lock.fill", "No account, no cloud",
                 "Your name, picture, and every entry are stored only on this \(LocalAssets.deviceName).")
            fact("cpu.fill", "Understanding", model.usesMocks ? "Mock mode: a stand-in is answering." : model.interpreterName)
            fact("waveform", "Listening", model.usesMocks ? "Mock mode: no microphone." : "Argmax WhisperKit, on this \(LocalAssets.deviceName)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.l)
        .stickerCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 18)
        .animation(Motion.present.delay(0.45), value: appeared)
    }

    private func fact(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Theme.paper)
                .frame(width: 34, height: 34)
                .background(Theme.ink.opacity(0.85), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.headline).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.caption).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            Text("Your other device").font(Theme.title).foregroundStyle(Theme.ink)
            Text(model.syncStatus ?? "Copy your entries, budgets, name and picture between your Mac and iPhone over Bluetooth. No internet involved. Tap Sync on both.")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
            Button(model.isSyncing ? "Stop" : "Sync now", systemImage: "arrow.triangle.2.circlepath") { model.startSync() }
                .buttonStyle(ChunkyButtonStyle(fill: Theme.ink, edge: Theme.edge.opacity(0.5), foreground: Theme.paper, radius: 14))
                .symbolEffect(.rotate, isActive: model.isSyncing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Space.l)
        .stickerCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 18)
        .animation(Motion.present.delay(0.55), value: appeared)
        .animation(Motion.move, value: model.syncStatus)
    }
}
