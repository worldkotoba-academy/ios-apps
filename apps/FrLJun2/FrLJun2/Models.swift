import Foundation

// MARK: - データモデル（app_data/futsuken_<級>.json と対応）

struct AppData: Codable {
    let levels: [ExamLevel]
}

struct ExamLevel: Codable, Identifiable, Hashable {
    let level: String        // "準2級"
    let key: String
    let subtitle: String
    let official: String     // 本試験の合格基準（そのまま表示する）
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
    /// 記述式（自己採点）の設問
    var writtenQuestions: [(ExamSection, ExamQuestion)] {
        sections.filter { $0.type == .write }.flatMap { s in s.questions.map { (s, $0) } }
    }
    var hasWritten: Bool { sections.contains { $0.type == .write } }
}

/// 出題の型。仏検は級ごとに大問の形式が違うので5種類に正規化してある。
enum SectionKind: String, Codable {
    case qlist      // 設問ごとの選択肢
    case shared     // 大問で共有する選択肢群から選ぶ（同じ語は1度だけ）
    case illust     // 短文に合う絵を選ぶ
    case truefalse  // 本文の内容と一致するか
    case write      // 記述式（自己採点）
}

struct ExamSection: Codable, Identifiable {
    let no: Int
    let title: String
    let type: SectionKind
    let instruction: String
    let pointsPerQ: Double
    let context: String?
    let example: String?
    let sharedChoices: [String]
    let questions: [ExamQuestion]
    var id: Int { no }

    var hasContext: Bool { !(context ?? "").isEmpty }
    /// 語群を表示するか（記述式でも語群を伴う大問がある）
    var showsSharedChoices: Bool { !sharedChoices.isEmpty }
    var maxPoints: Double { questions.reduce(0) { $0 + points(for: $1) } }
    func points(for q: ExamQuestion) -> Double { q.points ?? pointsPerQ }

    /// この設問で提示する選択肢（shared 型は大問の共有選択肢）
    func choices(for q: ExamQuestion) -> [String] {
        type == .shared ? sharedChoices : (q.choices ?? [])
    }
}

struct ExamQuestion: Codable, Identifiable, Hashable {
    let label: String        // "(12)"
    let stem: String
    let prompt: String?      // 記述式の問い（和文・原文・設問文）
    let choices: [String]?
    let scenes: [String]?    // illust 型：同梱PNGの名前
    let answer: Int?         // 1 始まり（記述式は nil）
    let answerText: String?  // 記述式の解答例
    let charLimit: Int?
    let points: Double?
    let translation: String?
    let explanation: String?
    var id: String { label }

    static func == (l: ExamQuestion, r: ExamQuestion) -> Bool { l.label == r.label }
    func hash(into h: inout Hasher) { h.combine(label) }
}

// MARK: - 読み込み

enum ExamData {
    static let shared: AppData = {
        guard let url = Bundle.main.url(forResource: "futsuken_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data)
        else { fatalError("futsuken_data.json が読み込めません") }
        return decoded
    }()

    /// 本アプリが収録する唯一の級
    static var level: ExamLevel { shared.levels[0] }
}

// MARK: - 表記ヘルパ

private let circledNumbers = ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]

func circled(_ i: Int) -> String {
    (1...circledNumbers.count).contains(i) ? circledNumbers[i - 1] : "\(i)"
}

/// 配点の表示（7.5 のような小数はそのまま、整数は小数点なしで出す）
func pts(_ v: Double) -> String {
    v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
}
