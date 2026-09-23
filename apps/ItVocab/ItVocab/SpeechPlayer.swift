import AVFoundation
import SwiftUI

/// 学習言語の読み上げ。音声は **iOS 標準の音声合成のみ**（音声ファイルは同梱しない）。
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechPlayer()

    @Published var speakingKey: String? = nil
    private let synth = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synth.delegate = self
    }

    private func voice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(SPEECH_PREFIX) }
        if let v = voices.first(where: { $0.language == SPEECH_LANG && ($0.quality == .enhanced || $0.quality == .premium) }) { return v }
        if let v = voices.first(where: { $0.language == SPEECH_LANG }) { return v }
        if let v = voices.first(where: { $0.quality == .enhanced || $0.quality == .premium }) { return v }
        return voices.first ?? AVSpeechSynthesisVoice(language: SPEECH_LANG)
    }

    func speak(_ text: String, key: String, slow: Bool = false) {
        stop()
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        let u = AVSpeechUtterance(string: body)
        u.voice = voice()
        u.rate = slow ? AVSpeechUtteranceDefaultSpeechRate * 0.55 : AVSpeechUtteranceDefaultSpeechRate * 0.9
        speakingKey = key
        synth.speak(u)
    }

    func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        speakingKey = nil
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        DispatchQueue.main.async { self.speakingKey = nil }
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) {
        DispatchQueue.main.async { self.speakingKey = nil }
    }
}

/// 小さなスピーカーボタン
struct SpeakButton: View {
    let text: String
    let key: String
    var slow: Bool = false
    var label: String? = nil
    @ObservedObject private var speech = SpeechPlayer.shared

    var body: some View {
        let active = speech.speakingKey == key
        Button {
            if active { speech.stop() } else { speech.speak(text, key: key, slow: slow) }
        } label: {
            Label(label ?? (slow ? "ゆっくり" : "読み上げ"),
                  systemImage: active ? "stop.circle.fill" : (slow ? "tortoise.fill" : "speaker.wave.2.fill"))
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(active ? Color.vcRed.opacity(0.15) : Color.vcAccent.opacity(0.12))
                .foregroundColor(active ? .vcRed : .vcAccent)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
