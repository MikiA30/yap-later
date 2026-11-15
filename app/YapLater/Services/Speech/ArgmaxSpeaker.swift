import Foundation
#if canImport(TTSKit)
import TTSKit

/// Speaks with Argmax TTSKit (Qwen3-TTS 0.6B as Core ML models), entirely on the device.
/// Until its model is loaded, or when the model is not on the device, the system voice speaks instead.
@MainActor
final class ArgmaxSpeaker: Speaker {
    private let fallback = SystemSpeaker()
    private var tts: TTSKit?
    private var speaking: Task<Void, Never>?
    private var loading: Task<Void, Never>?

    /// `<assets>/tts`: the downloaded model, and `tokenizer/` beside it.
    static var folder: URL? { LocalAssets.root?.appendingPathComponent("tts", isDirectory: true) }
    private static var tokenizerFolder: URL? {
        guard let folder = folder?.appendingPathComponent("tokenizer", isDirectory: true),
              FileManager.default.fileExists(atPath: folder.appendingPathComponent("tokenizer.json").path)
        else { return nil }
        return folder
    }

    /// The model folder when the voice model is already on the device.
    static var modelFolder: URL? {
        guard let folder = folder?.appendingPathComponent("models/argmaxinc/ttskit-coreml", isDirectory: true),
              FileManager.default.fileExists(atPath: folder.appendingPathComponent("qwen3_tts").path)
        else { return nil }
        return folder
    }

    /// True when the voice can load with no network: model and tokenizer are both on the device.
    static var isProvisioned: Bool { modelFolder != nil && tokenizerFolder != nil }

    /// Whether the app should speak with this voice. On the Mac: whenever the model is there.
    /// On the iPhone it also needs the marker file `tts/enabled`, added once the voice and the microphone
    /// have been checked together on that phone; until then the system voice stays in charge.
    static var isEnabled: Bool {
        guard isProvisioned else { return false }
        #if os(macOS)
        return true
        #else
        guard let marker = folder?.appendingPathComponent("enabled") else { return false }
        return FileManager.default.fileExists(atPath: marker.path)
        #endif
    }

    var isReady: Bool { tts != nil }

    /// Loads the voice model in the background. With `download`, a missing model is fetched once (needs a network).
    func prepare(download: Bool = false) {
        guard tts == nil, loading == nil, let base = Self.folder else { return }
        loading = Task { [weak self] in
            let started = Date()
            do {
                let local = Self.isProvisioned ? Self.modelFolder : nil
                guard local != nil || download else {
                    self?.loading = nil
                    return
                }
                let config = TTSKitConfig(model: .qwen3TTS_0_6b, modelFolder: local, downloadBase: base,
                                          tokenizerFolder: Self.tokenizerFolder,
                                          verbose: false, download: local == nil, load: true)
                let kit = try await TTSKit(config)
                self?.tts = kit
                print("TTS ready in \(Int(Date().timeIntervalSince(started) * 1000)) ms, folder: \(kit.modelFolder?.path ?? "nil")")
            } catch {
                print("TTS unavailable, using the system voice: \(error)")
            }
            self?.loading = nil
        }
    }

    func speak(_ text: String) {
        stop()
        guard let tts else {
            fallback.speak(text)
            return
        }
        speaking = Task { [weak self] in
            let started = Date()
            do {
                var first: Date?
                _ = try await tts.play(text: text, speaker: .serena, language: .english) { _ in
                    if first == nil { first = Date() }
                    return !Task.isCancelled
                }
                print("TTS spoke \"\(text)\": first audio \(Int((first ?? Date()).timeIntervalSince(started) * 1000)) ms, total \(Int(Date().timeIntervalSince(started) * 1000)) ms")
            } catch is CancellationError {
            } catch {
                print("TTS failed, using the system voice: \(error)")
                if !Task.isCancelled { self?.fallback.speak(text) }
            }
        }
    }

    func stop() {
        speaking?.cancel()
        speaking = nil
        fallback.stop()
    }
}
#endif
