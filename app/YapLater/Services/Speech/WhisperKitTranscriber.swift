import AVFoundation
import Foundation
import WhisperKit

/// Hold-to-talk speech recognition with Argmax WhisperKit. Audio never leaves the phone.
actor WhisperKitTranscriber: SpeechTranscriber {
    nonisolated let isMock = false

    /// Folder name of the Core ML model, as published in argmaxinc/whisperkit-coreml.
    private let modelName: String
    private var kit: WhisperKit?
    private var loading: Task<WhisperKit, Error>?
    private var levelTask: Task<Void, Never>?
    private var recording = false

    /// Shown to Whisper as earlier text so it writes amounts as words ("six fifty"), not bare digits ("650").
    /// Digits lose the difference between $6.50 and $650; the words keep it for the model to read.
    static let defaultPrompt = "Spent six fifty on coffee. Lunch was thirteen forty five. Paid six hundred fifty dollars for rent. Twenty two dollars on gas."
    private let prompt: String?

    init(modelName: String = "openai_whisper-small", prompt: String? = WhisperKitTranscriber.defaultPrompt) {
        self.modelName = modelName
        self.prompt = ProcessInfo.processInfo.environment["YAP_WHISPER_PROMPT"] ?? prompt
    }

    /// `Documents/speech/<model>` when the model was copied onto the phone ahead of time.
    static func provisionedFolder(named name: String) -> URL? {
        guard let documents = LocalAssets.root else { return nil }
        let folder = documents.appendingPathComponent("speech/\(name)", isDirectory: true)
        let encoder = folder.appendingPathComponent("AudioEncoder.mlmodelc")
        return FileManager.default.fileExists(atPath: encoder.path) ? folder : nil
    }

    func prepare() async throws { _ = try await loadedKit() }

    private func loadedKit() async throws -> WhisperKit {
        if let kit { return kit }
        if let loading { return try await loading.value }
        let name = modelName
        let task = Task { () -> WhisperKit in
            let config: WhisperKitConfig
            if let folder = Self.provisionedFolder(named: name) {
                // Fully offline: model and tokenizer are already on the phone.
                config = WhisperKitConfig(modelFolder: folder.path, tokenizerFolder: folder,
                                          verbose: false, logLevel: .error,
                                          prewarm: false, load: true, download: false)
            } else {
                // First run with a connection: download once, then it is cached for offline use.
                config = WhisperKitConfig(model: name.replacingOccurrences(of: "openai_whisper-", with: ""),
                                          verbose: false, logLevel: .error,
                                          prewarm: false, load: true, download: true)
            }
            return try await WhisperKit(config)
        }
        loading = task
        do {
            let loaded = try await task.value
            kit = loaded
            loading = nil
            return loaded
        } catch {
            loading = nil
            throw SpeechError.failed("\(error)")
        }
    }

    func start(onLevel: @escaping @Sendable (Float) -> Void) async throws {
        guard await AudioProcessor.requestRecordPermission() else { throw SpeechError.microphoneDenied }
        let kit = try await loadedKit()
        levelTask?.cancel()
        kit.audioProcessor.purgeAudioSamples(keepingLast: 0)
        do {
            try kit.audioProcessor.startRecordingLive(inputDeviceID: nil, callback: nil)
        } catch {
            throw SpeechError.failed("\(error)")
        }
        recording = true
        levelTask = Task {
            while !Task.isCancelled {
                onLevel(min(max(kit.audioProcessor.relativeEnergy.last ?? 0, 0), 1))
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    func stop() async throws -> String {
        levelTask?.cancel()
        guard recording, let kit else { return "" }
        recording = false
        kit.audioProcessor.stopRecording()
        let samples = Array(kit.audioProcessor.audioSamples)
        guard samples.count > 16_000 / 3 else { return "" } // under a third of a second: nothing was said
        let started = Date()
        let text = try await transcribe(samples: samples, prompt: prompt)
        #if DEBUG
        print("YAP speech: \(String(format: "%.1f", Double(samples.count) / 16_000)) s of audio transcribed in \(Int(Date().timeIntervalSince(started) * 1000)) ms")
        #endif
        return text
    }

    /// Transcribes 16 kHz mono samples. `prompt` biases the writing style (see `defaultPrompt`).
    func transcribe(samples: [Float], prompt: String?) async throws -> String {
        let kit = try await loadedKit()
        var options = DecodingOptions(task: .transcribe, language: "en", temperature: 0,
                                      skipSpecialTokens: true, withoutTimestamps: true)
        if let prompt, !prompt.isEmpty, let tokenizer = kit.tokenizer {
            options.promptTokens = tokenizer.encode(text: " " + prompt)
                .filter { $0 < tokenizer.specialTokens.specialTokenBegin }
        }
        do {
            let results = try await kit.transcribe(audioArray: samples, decodeOptions: options)
            return results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw SpeechError.failed("\(error)")
        }
    }

    func cancel() async {
        levelTask?.cancel()
        guard recording else { return }
        recording = false
        kit?.audioProcessor.stopRecording()
    }
}
