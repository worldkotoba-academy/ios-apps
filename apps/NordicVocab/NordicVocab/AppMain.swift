import SwiftUI

@main
struct VocabApp: App {
    var body: some Scene {
        WindowGroup {
            root.tint(.vcAccent)
        }
    }

    @ViewBuilder
    private var root: some View {
        #if DEBUG
        if let shot = ScreenshotScene.current { shot.view } else { HomeView() }
        #else
        HomeView()
        #endif
    }
}

#if DEBUG
// MARK: - ストア用スクリーンショットの撮影モード（Debug ビルドだけ・製品版には入らない）
// 環境変数 SHOT で開く画面を指定する（ios-apps の ios-shots.yml がシミュレータで起動して撮影）。
//   home:<言語> / level:<級>:<言語> / part:<級>:<テーマ>:<言語> / detail:<級>:<テーマ>:<語>:<言語> / card:<級>:<テーマ>:<言語> / quiz:<級>:<テーマ>:<言語>
//   <言語> は sv / no / da

struct ScreenshotScene {
    let parts: [String]

    static let current: ScreenshotScene? = {
        guard let s = ProcessInfo.processInfo.environment["SHOT"], !s.isEmpty else { return nil }
        let p = s.components(separatedBy: ":")
        if let l = p.last, TRIO_LANGS.contains(where: { $0.code == l }) { LangStore.shared.code = l }
        seed()
        return ScreenshotScene(parts: p)
    }()

    private func int(_ i: Int) -> Int { i < parts.count ? Int(parts[i]) ?? 0 : 0 }
    private var level: VocabLevel { Vocab.levels[min(int(1), Vocab.levels.count - 1)] }
    private var part: VocabPart { level.parts[min(int(2), level.parts.count - 1)] }

    @ViewBuilder var view: some View {
        switch parts.first ?? "" {
        case "level":  Self.pushed(LevelView(level: level))
        case "part":   Self.pushed(PartView(level: level, part: part))
        case "detail": Self.pushed(WordDetailView(words: part.words, index: min(int(3), part.words.count - 1)))
        case "card":   Self.pushed(FlashcardView(title: part.title, words: part.words, startFlipped: true))
        case "quiz":   Self.pushed(QuizView(title: part.title, words: part.words, autoStart: true))
        default:       HomeView()
        }
    }

    private static func pushed<V: View>(_ v: V) -> some View {
        NavigationStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
                .navigationTitle(APP_TITLE)
                .navigationDestination(isPresented: .constant(true)) { v }
        }
    }

    /// 学習の進み具合の見本（初級の前半を「覚えた」、いくつかを苦手・お気に入りに）
    private static func seed() {
        for k in [".known", ".weak", ".favorite"] { UserDefaults.standard.removeObject(forKey: STORE_PREFIX + k) }
        let words = Vocab.levels[0].words
        for (i, w) in words.prefix(240).enumerated() {
            if i % 11 == 5 { Store.shared.markWeak(w.id) } else { Store.shared.setKnown(w.id, true) }
            if i % 17 == 3 { Store.shared.toggleFavorite(w.id) }
        }
        for w in Vocab.levels.dropFirst().flatMap({ $0.words }).prefix(90) { Store.shared.setKnown(w.id, true) }
    }
}
#endif
