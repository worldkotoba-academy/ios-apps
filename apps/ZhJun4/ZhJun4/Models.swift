import Foundation
import SwiftUI

// MARK: - データモデル（app_data/<検定>_<級>.json と対応）
// 語学検定の模試アプリ共通。級ごとの違いは Config.swift（ビルド時生成）に置く。

struct AppData: Codable {
    let levels: [ExamLevel]
}

struct ExamLevel: Codable, Identifiable, Hashable {
    let level: String        // "準2級" / "B2（DIPLE）"
    let key: String
    let subtitle: String
    let official: String     // 配点・合格点についての注記（そのまま表示）
    let passNote: String
    let rounds: [ExamRound]
    var id: String { key }

    static func == (l: ExamLevel, r: ExamLevel) -> Bool { l.key == r.key }
    func hash(into h: inout Hasher) { h.combine(key) }
}

struct ExamRound: Codable, Identifiable, Hashable {
    let round: Int
    let title: String
    let durationMin: Int
    let totalPoints: Int
    let passing: Int
    let sections: [ExamSection]
    var id: Int { round }

    static func == (l: ExamRound, r: ExamRound) -> Bool { l.round == r.round }
    func hash(into h: inout Hasher) { h.combine(round) }

    var questionCount: Int { sections.reduce(0) { $0 + $1.questions.count } }
    /// 自己採点が必要な設問（記述式）
    var writtenQuestions: [(ExamSection, ExamQuestion)] {
        sections.flatMap { s in s.questions.filter { $0.kind == .write }.map { (s, $0) } }
    }
    var hasWritten: Bool { sections.contains { s in s.questions.contains { $0.kind == .write } } }
}

/// 大問の見せ方
enum SectionLayout: String, Codable {
    case plain      // 設問だけ
    case context    // 本文・掲示・グラフ・挿絵を先に出す
    case match      // 大問共通の選択肢から選ぶ
}

/// 設問の種類
enum QuestionKind: String, Codable {
    case choice     // 1つ選ぶ
    case multi      // N個選ぶ（順不同）
    case write      // 記述（解答例と見比べる自己採点）
    case input      // 短答（入力を自動採点）
}

struct ChartSpec: Codable, Hashable {
    let title: String
    let categories: [String]
    let values: [Double]
    let unit: String?
    let max: Double?
    let source: String?
}

struct ExamSection: Codable, Identifiable {
    let no: Int
    let code: String              // "PARTE 1" / "第1問"
    let title: String
    let layout: SectionLayout
    let instruction: String
    let pointsPerQ: Double
    let contextTitle: String?
    let context: String?
    let contextTranslation: String?
    let contextSource: String?
    let sharedChoicesTitle: String?
    let sharedChoices: [String]
    let chart: ChartSpec?
    let image: String?            // 同梱 PNG のファイル名（拡張子なし）
    let questions: [ExamQuestion]
    var id: Int { no }

    var hasContext: Bool { !(context ?? "").isEmpty || !(image ?? "").isEmpty }
    var maxPoints: Double { questions.reduce(0) { $0 + $1.points } }

    /// この設問で提示する選択肢（match レイアウトは大問共通）
    func choices(for q: ExamQuestion) -> [String] {
        if let c = q.choices, !c.isEmpty { return c }
        return sharedChoices
    }
}

struct ExamQuestion: Codable, Identifiable, Hashable {
    let label: String
    let kind: QuestionKind
    let stem: String
    let prompt: String?      // 掲示・本文の一部・書き換えのもとの文など、設問の前に出す枠
    let hint: String?        // 条件・書き出しの指定・注記
    let choices: [String]?
    let answer: Int?         // choice：1始まり
    let answers: [Int]?      // multi：1始まりの集合
    let numSelect: Int?
    let scoring: String?     // multi："each"＝1つ正解ごと／"all"＝全部正解で満点
    let choiceNotes: [String]?
    let answerText: String?  // write / input：解答例（input は accepted の先頭を表示）
    let accepted: [String]?  // input：正解として受け付ける表記
    let points: Double
    let translation: String?
    let explanation: String?
    let spoken: String?      // 読み上げ用に整えた文
    var id: String { label }

    static func == (l: ExamQuestion, r: ExamQuestion) -> Bool { l.label == r.label }
    func hash(into h: inout Hasher) { h.combine(label) }

    var answerSet: Set<Int> { Set(answers ?? []) }

    /// 選択式の得点
    func score(selected: Set<Int>) -> Double {
        switch kind {
        case .choice:
            guard let a = answer else { return 0 }
            return selected == [a] ? points : 0
        case .multi:
            let n = Double(numSelect ?? answerSet.count)
            let hit = Double(selected.intersection(answerSet).count)
            if scoring == "all" { return selected == answerSet ? points : 0 }
            // 1つ正解ごと。余分に選んだ分は差し引く（0未満にはしない）
            let extra = Double(selected.subtracting(answerSet).count)
            return Swift.max(0, (hit - extra) * (points / n))
        case .write, .input:
            return 0
        }
    }

    /// 短答（input）の自動採点。大文字小文字・前後の空白・句読点の違いは吸収する。
    func matches(_ typed: String) -> Bool {
        let t = ExamQuestion.normalize(typed)
        guard !t.isEmpty else { return false }
        return (accepted ?? []).contains { ExamQuestion.normalize($0) == t }
    }

    func scoreTyped(_ typed: String) -> Double {
        kind == .input ? (matches(typed) ? points : 0) : 0
    }

    static func normalize(_ s: String) -> String {
        var t = s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        t = t.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"^[「『（(]+|[」』）)、。，．,.!?！？;；:：]+$"#,
                                   with: "", options: .regularExpression)
        return t
    }
}

// MARK: - 読み込み

enum ExamData {
    static let shared: AppData = {
        guard let url = Bundle.main.url(forResource: DATA_NAME, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data)
        else { fatalError("\(DATA_NAME).json が読み込めません") }
        return decoded
    }()
    static var level: ExamLevel { shared.levels[0] }
}

// MARK: - 表記ヘルパ

private let circledMarks = ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]
private let letterMarks = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
private let lowerMarks = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]

/// 選択肢の記号。本試験の表記に合わせて Config で切り替える。
func mark(_ i: Int) -> String {
    let list: [String]
    switch MARK_STYLE {
    case "letter": list = letterMarks
    case "lower":  list = lowerMarks
    default:       list = circledMarks
    }
    return (1...list.count).contains(i) ? list[i - 1] : "\(i)"
}

func pts(_ v: Double) -> String {
    v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
}

/// 読み上げ対象の言語らしい文字列か（日本語の解説を読み上げないための判定）
func isTargetLanguage(_ s: String) -> Bool {
    var hit = 0
    for u in s.unicodeScalars {
        switch SCRIPT {
        case "hangul":
            if (0xAC00...0xD7A3).contains(u.value) || (0x1100...0x11FF).contains(u.value) { hit += 1 }
        case "han":
            // 仮名が混じる行は日本語とみなす
            if (0x3040...0x30FF).contains(u.value) || (0xFF66...0xFF9F).contains(u.value) { return false }
            if (0x4E00...0x9FFF).contains(u.value) { hit += 1 }
        default:
            if (0x3040...0x30FF).contains(u.value) || (0x4E00...0x9FFF).contains(u.value)
                || (0xFF66...0xFF9F).contains(u.value) || (0xAC00...0xD7A3).contains(u.value) { return false }
            if (0x41...0x5A).contains(u.value) || (0x61...0x7A).contains(u.value)
                || (0xC0...0x24F).contains(u.value) { hit += 1 }
        }
    }
    return hit >= 2
}

/// 学習言語の本文に使うフォント。中国語のように日本語と字形が異なる言語では
/// Config の CONTENT_FONT にその言語のフォントを指定する（空なら端末の標準フォント）。
func contentFont(_ style: Font.TextStyle, _ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    CONTENT_FONT.isEmpty ? Font.system(style).weight(weight)
                         : Font.custom(CONTENT_FONT, size: size, relativeTo: style).weight(weight)
}
