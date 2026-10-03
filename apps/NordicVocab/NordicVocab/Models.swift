import Foundation
import SwiftUI

// MARK: - データモデル（vocab_data.json と対応）

struct VocabData: Codable {
    let language: String
    let levels: [VocabLevel]
}

struct VocabLevel: Codable, Identifiable, Hashable {
    let key: String          // "beginner"
    let name: String         // "初級"
    let badge: String        // "DELE A1・A2 相当"
    let subtitle: String
    let count: Int
    let parts: [VocabPart]
    var id: String { key }

    static func == (l: VocabLevel, r: VocabLevel) -> Bool { l.key == r.key }
    func hash(into h: inout Hasher) { h.combine(key) }

    var words: [VocabWord] { parts.flatMap { $0.words } }
}

struct VocabPart: Codable, Identifiable, Hashable {
    let no: Int
    let title: String
    let sub: String
    let words: [VocabWord]
    var id: Int { no }

    static func == (l: VocabPart, r: VocabPart) -> Bool { l.no == r.no }
    func hash(into h: inout Hasher) { h.combine(no) }
}

/// 1つの言語ぶんの見出し・発音・例文
struct TrioEntry: Codable, Hashable {
    let word: String
    let kana: String         // カナ発音
    let pos: String          // 品詞（性つき：名詞（共性）など）
    let posGroup: String     // バッジの色分け用
    let example: String
    let exampleJa: String
}

/// 北欧3言語の単語。日本語の見出し（meaning）1つに、3言語の語が並ぶ。
/// word・kana・example などは「いま学習中の言語」（LangStore）のものを返す。
struct VocabWord: Codable, Identifiable, Hashable {
    let key: String          // "beginner-1"（級をまたいで一意・言語をまたいで共通）
    let no: Int
    let meaning: String      // 日本語の見出し
    let note: String?
    let langs: [String: TrioEntry]   // "sv" / "no" / "da"

    var entry: TrioEntry { langs[LangStore.current] ?? langs.values.first! }
    /// 学習状態のキーは言語ごと（スウェーデン語で覚えた語がデンマーク語でも「覚えた」にならないように）
    var id: String { key + "@" + LangStore.current }
    var word: String { entry.word }
    var kana: String { entry.kana }
    var pos: String { entry.pos }
    var posGroup: String { entry.posGroup }
    var example: String { entry.example }
    var exampleJa: String { entry.exampleJa }

    static func == (l: VocabWord, r: VocabWord) -> Bool { l.key == r.key }
    func hash(into h: inout Hasher) { h.combine(key) }
}

// MARK: - 学習中の言語

/// 言語の定義（Config.swift の TRIO_LANGS に並べる）
struct TrioLang {
    let code: String         // "sv"
    let name: String         // "スウェーデン語"
    let short: String        // "典"
    let speech: String       // "sv-SE"
    let prefixes: [String]   // 声を探す接頭辞
    let field: Color         // 国旗の地
    let crossOuter: Color    // 十字（外）
    let crossInner: Color?   // 十字（内）。ノルウェーだけ
}

/// 3言語のうち、いま学習している言語（端末内に保存）
final class LangStore: ObservableObject {
    static let shared = LangStore()
    private static let k = STORE_PREFIX + ".lang"
    /// 単語の計算プロパティから毎回参照するので static に持つ
    private(set) static var current: String = UserDefaults.standard.string(forKey: k) ?? TRIO_LANGS[0].code

    @Published var code: String = LangStore.current {
        didSet {
            LangStore.current = code
            UserDefaults.standard.set(code, forKey: Self.k)
            SpeechPlayer.shared.stop()
        }
    }
    var info: TrioLang { TRIO_LANGS.first { $0.code == code } ?? TRIO_LANGS[0] }
    static func info(_ code: String) -> TrioLang { TRIO_LANGS.first { $0.code == code } ?? TRIO_LANGS[0] }
}

/// 国旗（北欧十字）を小さく描く
struct NordicFlag: View {
    let lang: TrioLang
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                Rectangle().fill(lang.field)
                // 十字（縦は旗竿寄り）。外枠の色→内側の色の順に重ねる
                Rectangle().fill(lang.crossOuter).frame(width: w * 0.22, height: h).offset(x: w * 0.28)
                Rectangle().fill(lang.crossOuter).frame(width: w, height: h * 0.32).offset(y: h * 0.34)
                if let inner = lang.crossInner {
                    Rectangle().fill(inner).frame(width: w * 0.11, height: h).offset(x: w * 0.335)
                    Rectangle().fill(inner).frame(width: w, height: h * 0.16).offset(y: h * 0.42)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

/// 学習言語の本文に使うフォント。Config の CONTENT_FONT が空なら端末の標準フォント。
/// 中国語のように「日本語と共通の字でも字形が違う」言語で必要（直・骨・教 など）。
func contentFont(_ size: CGFloat, _ weight: Font.Weight = .regular,
                 relativeTo style: Font.TextStyle = .body) -> Font {
    CONTENT_FONT.isEmpty ? Font.system(size: size, weight: weight)
                         : Font.custom(CONTENT_FONT, size: size, relativeTo: style).weight(weight)
}

// MARK: - 読み込み

enum Vocab {
    static let shared: VocabData = {
        guard let url = Bundle.main.url(forResource: "vocab_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(VocabData.self, from: data)
        else { fatalError("vocab_data.json が読み込めません") }
        return decoded
    }()

    static var levels: [VocabLevel] { shared.levels }
    static var allWords: [VocabWord] { shared.levels.flatMap { $0.words } }

    static func level(for word: VocabWord) -> VocabLevel? {
        shared.levels.first { $0.key == word.key.split(separator: "-").first.map(String.init) }
    }
}

// MARK: - 品詞バッジの色

func posColor(_ group: String) -> Color {
    switch group {
    case "noun":    return Color(red: 0.91, green: 0.30, blue: 0.24)   // 名詞
    case "verb":    return Color(red: 0.20, green: 0.60, blue: 0.86)   // 動詞
    case "adj":     return Color(red: 0.15, green: 0.68, blue: 0.38)   // 形容詞
    case "adv":     return Color(red: 0.61, green: 0.35, blue: 0.71)   // 副詞
    case "prep":    return Color(red: 0.90, green: 0.49, blue: 0.13)   // 前置詞
    case "conj":    return Color(red: 0.09, green: 0.63, blue: 0.52)   // 接続詞
    case "phrase":  return Color(red: 0.75, green: 0.22, blue: 0.17)   // 慣用句・表現
    default:        return Color(red: 0.45, green: 0.49, blue: 0.53)   // その他
    }
}

/// 数を「1,234」の形にする
func grouped(_ n: Int) -> String {
    let f = NumberFormatter(); f.numberStyle = .decimal
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}
