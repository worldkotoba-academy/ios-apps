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

struct VocabWord: Codable, Identifiable, Hashable {
    let id: String           // "beginner-1"（級をまたいで一意。学習状態のキー）
    let no: Int
    let word: String
    let kana: String         // カナ発音
    let pos: String          // 品詞（原文のまま）
    let posGroup: String     // バッジの色分け用
    let meaning: String
    let example: String
    let exampleJa: String
    let note: String?        // 文法メモ（体のペア・性・格支配など）。無い言語では nil

    static func == (l: VocabWord, r: VocabWord) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
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
        shared.levels.first { $0.key == word.id.split(separator: "-").first.map(String.init) }
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
