import Foundation

/// Turns one held-to-talk recording into text. The real implementation (T020/T012) runs on the phone.
protocol SpeechTranscriber: Sendable {
    /// `true` when this is a stand-in, so the UI can label it.
    var isMock: Bool { get }
    func transcribe() async throws -> String
}

/// MOCK: returns canned sentences in order. No microphone, no speech model.
actor MockTranscriber: SpeechTranscriber {
    nonisolated let isMock = true
    private var index = 0
    static let script = [
        "Just spent like fifty bucks on groceries at Walmart",
        "Grabbed a coffee, six fifty",
        "Twenty two dollars on an Uber home",
    ]

    func transcribe() async throws -> String {
        try await Task.sleep(for: .milliseconds(700))
        defer { index += 1 }
        return Self.script[index % Self.script.count]
    }
}
