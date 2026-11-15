import AVFoundation

/// Speaks short lines aloud: ask-back questions and nudges. On-device voices only.
@MainActor
protocol Speaker: AnyObject {
    func speak(_ text: String)
    func stop()
}

@MainActor
final class SystemSpeaker: Speaker {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        synthesizer.speak(utterance)
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}

/// Says nothing; records what would have been said. For tests and previews.
@MainActor
final class SilentSpeaker: Speaker {
    private(set) var spoken: [String] = []
    func speak(_ text: String) { spoken.append(text) }
    func stop() {}
}
