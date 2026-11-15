import SwiftUI

/// The app's top-level screen. Everything visible hangs off this.
struct RootView: View {
    @Bindable var model: AppModel
    @State private var handledRequests = 0

    var body: some View {
        HomeView(model: model)
            // Action Button / Shortcuts: start listening as soon as the app is in front.
            .onChange(of: YapTrigger.shared.requests, initial: true) { _, requests in
                guard requests > handledRequests else { return }
                handledRequests = requests
                model.beginYap()
            }
    }
}
