import SwiftUI

// このアプリのためにビルド時に生成される設定（アプリ本体のコードは全言語で共通）

let APP_TITLE = "北欧3言語単語帳"
let STORE_PREFIX = "nordicVocab"

// 読み上げ（iOS 標準の音声合成のみ）
let SPEECH_LANG = "sv-SE"
let SPEECH_PREFIX = "sv"

// 学習言語の本文フォント（空＝端末標準）。
// ★中国語は端末が日本語字形で描いてしまうので "PingFang SC" を指定する
let CONTENT_FONT = ""

let ABOUT_SECTIONS: [(String, String)] = [
    ("このアプリについて", "北欧3言語単語帳は、スウェーデン語・ノルウェー語・デンマーク語の3言語を同時に学べる単語帳アプリです。日本語の見出し3,000語それぞれに、3言語の単語・カナ発音・性（共性・中性）・例文と和訳を収録しています。学習する言語を切り替えて、カード学習・4択テスト・覚えた記録を言語ごとに進められます。単語の詳細画面では3言語を並べて比べられるので、よく似た3つの言語の違いと共通点が一目でわかります。"),
    ("レベルの区分について", "初級600語（あいさつ・数字・家族など）、中級1,000語（日常生活・社会と文化）、上級1,400語（自然と科学・感情と人間関係・抽象概念）の3段階です。この区分は学習の目安として独自に設定したものです。"),
    ("学習記録について", "「覚えた」「苦手」「お気に入り」の記録は言語ごとに端末内にのみ保存されます。レベル別・テーマ別に進捗が表示され、苦手な単語だけを集めて復習することもできます。"),
    ("語彙・例文の著作権", "収録されているすべての見出し語の配列・カナ発音・日本語訳・例文とその訳は、本アプリのために作成したオリジナルです。第三者の辞書・単語集を転載したものではありません。これらの著作権は制作者に帰属します。"),
    ("音声について", "3言語の読み上げには、iOS に標準搭載された音声合成機能（AVSpeechSynthesizer）のみを使用しています。第三者が権利を持つ音声データや録音は同梱していません。端末に各言語の音声が入っていない場合は、iOS の「設定 > アクセシビリティ > 読み上げコンテンツ > 声」からスウェーデン語・ノルウェー語・デンマーク語の音声を追加すると読み上げ品質が向上します。"),
    ("プライバシー", "本アプリは個人情報を一切収集しません。学習記録は端末内にのみ保存され、外部に送信されることはありません。通信機能・広告・解析ツールを使用していません。")
]

let FLAG_COLORS: [Color] = [Color(red: 0.000, green: 0.416, blue: 0.655), Color(red: 0.729, green: 0.047, blue: 0.184), Color(red: 0.784, green: 0.063, blue: 0.180)]

extension Color {
    static let vcAccent = Color(red: 0.078, green: 0.282, blue: 0.502)
    static let vcRed = Color(red: 0.784, green: 0.063, blue: 0.180)
    static let vcGold = Color(red: 0.839, green: 0.627, blue: 0.078)
}

// 学習する3言語（並び順＝表示順。最初が既定）
let TRIO_LANGS: [TrioLang] = [
    TrioLang(code: "sv", name: "スウェーデン語", short: "典", speech: "sv-SE", prefixes: ["sv"], field: Color(red: 0.000, green: 0.416, blue: 0.655), crossOuter: Color(red: 0.996, green: 0.800, blue: 0.000), crossInner: nil),
    TrioLang(code: "no", name: "ノルウェー語", short: "諾", speech: "nb-NO", prefixes: ["nb", "no"], field: Color(red: 0.729, green: 0.047, blue: 0.184), crossOuter: Color(red: 1.000, green: 1.000, blue: 1.000), crossInner: Color(red: 0.000, green: 0.125, blue: 0.357)),
    TrioLang(code: "da", name: "デンマーク語", short: "丁", speech: "da-DK", prefixes: ["da"], field: Color(red: 0.784, green: 0.063, blue: 0.180), crossOuter: Color(red: 1.000, green: 1.000, blue: 1.000), crossInner: nil)
]
