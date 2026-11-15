import Foundation

/// Hold-to-talk speech recognition. The real implementation runs entirely on the phone.
protocol SpeechTranscriber: Sendable {
    /// `true` when this is a stand-in, so the UI can label it.
    var isMock: Bool { get }
    /// Loads whatever is needed so the first `start` is fast. Safe to call more than once.
    func prepare() async throws
    /// Begins capturing. `onLevel` receives the input level, 0...1, several times a second.
    func start(onLevel: @escaping @Sendable (Float) -> Void) async throws
    /// Ends capturing and returns the transcript (possibly empty).
    func stop() async throws -> String
    /// Ends capturing and discards the audio.
    func cancel() async
}

enum SpeechError: Error, Equatable {
    case microphoneDenied
    case notReady
    case failed(String)
}

/// MOCK: returns canned sentences in order and fakes an input level. No microphone, no speech model.
actor MockTranscriber: SpeechTranscriber {
    nonisolated let isMock = true
    private var index = 0
    private var levelTask: Task<Void, Never>?

    static let script = [
        "Just spent like fifty bucks on groceries at Walmart",
        "Grabbed a coffee",
        "Six fifty",
        "Set my fun budget to forty a week",
        "Twenty two dollars on an Uber home",
    ]

    func prepare() async throws {}

    func start(onLevel: @escaping @Sendable (Float) -> Void) async throws {
        levelTask?.cancel()
        levelTask = Task {
            while !Task.isCancelled {
                onLevel(Float.random(in: 0.15...0.95))
                try? await Task.sleep(for: .milliseconds(90))
            }
        }
    }

    func stop() async throws -> String {
        levelTask?.cancel()
        try await Task.sleep(for: .milliseconds(350))
        defer { index += 1 }
        return Self.script[index % Self.script.count]
    }

    func cancel() async { levelTask?.cancel() }
}
