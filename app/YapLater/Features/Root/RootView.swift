import SwiftUI

/// The app's top-level screen. Everything visible hangs off this.
struct RootView: View {
    @Bindable var model: AppModel

    var body: some View {
        YapView(model: model)
    }
}
