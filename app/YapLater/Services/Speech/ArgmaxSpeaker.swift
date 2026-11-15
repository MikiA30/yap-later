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
    private var stopping: Task<Void, Never>?

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

    /// Whether the app should speak with this voice. The file `tts/voice.txt` holding "on" or "off" decides;
    /// without it the Mac uses the voice and the iPhone keeps the system voice, which answers instantly
    /// (on the iPhone 17 Pro this voice needs about 20 s to load and speaks a short line slower than real time).
    static var isEnabled: Bool {
        guard isProvisioned else { return false }
        if let file = folder?.appendingPathComponent("voice.txt"),
           let choice = try? String(contentsOf: file, encoding: .utf8) {
            return choice.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "on"
        }
        #if os(macOS)
        return true
        #else
        return false
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
        let silenced = stopping
        speaking = Task { [weak self] in
            await silenced?.value // the previous line has fully stopped before this one starts
            guard !Task.isCancelled else { return }
            let started = Date()
            do {
                var first: Date?
                _ = try await tts.play(text: Self.spokenForm(of: text), speaker: .serena, language: .english) { _ in
                    if first == nil { first = Date() }
                    return !Task.isCancelled
                }
                guard !Task.isCancelled else { return }
                print("TTS spoke \"\(text)\": first audio \(Int((first ?? Date()).timeIntervalSince(started) * 1000)) ms, total \(Int(Date().timeIntervalSince(started) * 1000)) ms")
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                print("TTS failed, using the system voice: \(error)")
                self?.fallback.speak(text)
            }
        }
    }

    /// Cuts the voice off at once: the user is about to talk, and the microphone must not hear the app.
    func stop() {
        fallback.stop()
        let interrupted = speaking
        speaking = nil
        interrupted?.cancel()
        guard let tts, interrupted != nil else { return }
        let earlier = stopping
        stopping = Task {
            await earlier?.value
            await tts.audioOutput.stopPlayback(waitForCompletion: false)
            await interrupted?.value
        }
    }

    /// Writes money the way it is said, so the voice does not have to guess: "$6.50" becomes "6 dollars and 50 cents".
    nonisolated static func spokenForm(of text: String) -> String {
        text.replacing(/\$(\d[\d,]*)(?:\.(\d\d))?/) { match in
            let dollars = String(match.1).replacingOccurrences(of: ",", with: "")
            let dollarWord = dollars == "1" ? "dollar" : "dollars"
            guard let cents = match.2, let value = Int(cents), value > 0 else { return "\(dollars) \(dollarWord)" }
            return "\(dollars) \(dollarWord) and \(value) \(value == 1 ? "cent" : "cents")"
        }
    }

}
#endif
