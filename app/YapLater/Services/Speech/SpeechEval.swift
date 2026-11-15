#if DEBUG
import AVFoundation

/// Debug tool: the phone speaks test phrases into memory (not out loud) and transcribes them, to see how
/// amounts get written with and without the vocabulary prompt. Synthetic voice, so it only shows formatting.
enum SpeechEval {
    static let phrases = [
        "Six fifty",
        "Grabbed a coffee, six fifty",
        "Lunch was thirteen forty five",
        "Spent two fifty on a soda",
        "I paid six hundred fifty dollars for rent",
        "Nineteen ninety nine for a shirt at Target",
        "Just spent fifty bucks on groceries at Walmart",
        "Set my coffee budget to twenty five a week",
    ]

    static func run(_ transcriber: WhisperKitTranscriber) async -> String {
        var lines: [String] = []
        for phrase in phrases {
            let samples = await synthesize(phrase)
            let plain = (try? await transcriber.transcribe(samples: samples, prompt: nil)) ?? "<failed>"
            let prompted = (try? await transcriber.transcribe(samples: samples, prompt: WhisperKitTranscriber.defaultPrompt)) ?? "<failed>"
            lines.append("said: \(phrase) | no prompt: \(plain) | prompt: \(prompted)")
        }
        return lines.joined(separator: "\n")
    }

    /// Speech for `text` as 16 kHz mono samples, with a little silence around it.
    static func synthesize(_ text: String) async -> [Float] {
        let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let speech: [Float] = await withCheckedContinuation { continuation in
            var samples: [Float] = []
            var finished = false
            synthesizer.write(utterance) { buffer in
                guard !finished, let pcm = buffer as? AVAudioPCMBuffer else { return }
                if pcm.frameLength == 0 {
                    finished = true
                    continuation.resume(returning: samples)
                    return
                }
                guard let converter = AVAudioConverter(from: pcm.format, to: target),
                      let converted = AVAudioPCMBuffer(
                        pcmFormat: target,
                        frameCapacity: AVAudioFrameCount(Double(pcm.frameLength) * 16_000 / pcm.format.sampleRate) + 256)
                else { return }
                var fed = false
                var error: NSError?
                converter.convert(to: converted, error: &error) { _, status in
                    if fed {
                        status.pointee = .endOfStream
                        return nil
                    }
                    fed = true
                    status.pointee = .haveData
                    return pcm
                }
                if let data = converted.floatChannelData {
                    samples.append(contentsOf: UnsafeBufferPointer(start: data[0], count: Int(converted.frameLength)))
                }
            }
        }
        _ = synthesizer
        let silence = [Float](repeating: 0, count: 6_400)
        return silence + speech + silence
    }
}
#endif
