import SwiftUI

@main
struct YapLaterApp: App {
    @State private var model = YapModel(
        transcriber: MockTranscriber(),
        interpreter: MockMoneyInterpreter()
    )

    var body: some Scene {
        WindowGroup {
            YapView(model: model)
        }
    }
}
