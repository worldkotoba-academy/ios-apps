import AVFoundation
import SwiftUI

/// 学習言語の読み上げ。
/// 音声は **iOS 標準の音声合成（AVSpeechSynthesizer）** のみを使用する。
/// 外部サービスで生成した音声ファイルは同梱していない（ライセンス上クリーン・完全オフライン）。
final class SpeechPlayer: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechPlayer()

    @Published var speakingKey: String? = nil
    private let synth = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synth.delegate = self
    }

    /// 空所記号・番号・強調マークは読み上げから外す
    private func clean(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: #"_{2,}\d*_{0,2}"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\(\s*\d*\s*\)"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[（(]\s*[）)]"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"[①-⑩*【】〔〕]"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"^[A-Za-z]\s*[:：]\s*"#, with: "", options: [.regularExpression])
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let body = clean(text)
        guard !body.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        let u = AVSpeechUtterance(string: body)
        u.voice = voice()
        u.rate = slow ? AVSpeechUtteranceDefaultSpeechRate * 0.55
                      : AVSpeechUtteranceDefaultSpeechRate * 0.88
        u.postUtteranceDelay = 0.1
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

/// 読み上げ／ゆっくり のボタン列
struct SpeakButtons: View {
    let text: String
    var idKey: String = ""
    var compact: Bool = false
    @ObservedObject private var speech = SpeechPlayer.shared

    var body: some View {
        HStack(spacing: 10) {
            button(slow: false, label: "読み上げ", icon: "speaker.wave.2.fill")
            if !compact { button(slow: true, label: "ゆっくり", icon: "tortoise.fill") }
        }
    }

    private func button(slow: Bool, label: String, icon: String) -> some View {
        let key = (idKey.isEmpty ? String(text.prefix(24)) : idKey) + (slow ? "#slow" : "")
        let active = speech.speakingKey == key
        return Button {
            if active { speech.stop() } else { speech.speak(text, key: key, slow: slow) }
        } label: {
            Label(active ? "停止" : label, systemImage: active ? "stop.circle.fill" : icon)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(active ? Color.exRed.opacity(0.15) : Color.exAccent.opacity(0.12))
                .foregroundColor(active ? .exRed : .exAccent)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
