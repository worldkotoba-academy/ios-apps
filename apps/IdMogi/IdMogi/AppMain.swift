import SwiftUI

@main
struct ExamMockApp: App {
    var body: some Scene {
        WindowGroup {
            root
                .tint(.exAccent)
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
// 起動時の環境変数 SHOT で開く画面を指定する。CI（ios-shots.yml）がシミュレータで起動して撮影する。
//   home（全級の一覧）/ level（級のホーム）/ round / study:<大問>:<設問>:<選んだ番号,…>[:1] / exam:<大問>:<残り秒>:<解答済み数>[:1] / result
//   （末尾の :1 は本文を畳んだ状態で開く）。先頭に lv:<級の番号>: を付けるとその級（既定は0＝最初の級）
//   撮影中は見せる級だけを購入済みとして扱う（ホームでは「購入済み」と「価格」の両方が写る）

struct ScreenshotScene {
    let parts: [String]

    static var levelIndex = 0

    static let current: ScreenshotScene? = {
        guard let s = ProcessInfo.processInfo.environment["SHOT"], !s.isEmpty else { return nil }
        var parts = s.components(separatedBy: ":")
        if parts.first == "lv", parts.count > 2 {
            levelIndex = min(max(Int(parts[1]) ?? 0, 0), ExamData.levels.count - 1)
            parts.removeFirst(2)
        }
        // 級のホーム（level）は未購入の状態（鍵と購入ボタン）を見せる。ほかは見せる級を購入済みにする
        let unlocked: Set<String> = parts.first == "level" ? [] : [level.key]
        MainActor.assumeIsolated { StoreManager.shared.screenshotUnlocked = unlocked }
        seedRecords()
        if parts.count > 4, parts[4] == "1" { ContextCard.startExpanded = false }   // 長い本文は畳んで設問を見せる
        return ScreenshotScene(parts: parts)
    }()

    private static var level: ExamLevel { ExamData.levels[levelIndex] }
    private static var round: ExamRound { level.rounds[0] }

    private func int(_ i: Int, _ d: Int = 0) -> Int { i < parts.count ? Int(parts[i]) ?? d : d }

    @ViewBuilder var view: some View {
        let level = Self.level, round = Self.round
        switch parts.first ?? "" {
        case "level":
            Self.pushed(LevelHomeView(level: level))
        case "round":
            Self.pushed(RoundHomeView(level: level, round: round))
        case "study":
            let si = min(int(1), round.sections.count - 1)
            let qi = min(int(2), round.sections[si].questions.count - 1)
            let q = round.sections[si].questions[qi]
            let sel = Set((parts.count > 3 ? parts[3] : "").split(separator: ",").compactMap { Int($0) })
            Self.pushed(StudyView(level: level, round: round, start: .init(
                section: si, page: qi,
                selections: sel.isEmpty ? [:] : [q.label: sel],
                typed: q.kind == .input ? [q.label: q.accepted?.first ?? ""] : [:],
                revealed: q.kind == .write ? [q.label] : [])))
        case "exam":
            let (sel, typed) = Self.answers(round, upTo: int(3, 12))
            Self.pushed(ExamView(level: level, round: round, start: .init(
                section: min(int(1), round.sections.count - 1), selections: sel, typed: typed, remaining: int(2, round.durationMin * 60 - 516))))
        case "result":
            let (sel, typed) = Self.answers(round, upTo: Int.max)
            Self.pushed(ResultView(level: level, round: round, selections: sel, typed: typed,
                                   record: Self.record(round, sel, typed, date: Date()))
                .navigationTitle("\(level.level) 第\(round.round)回　本番")
                .navigationBarTitleDisplayMode(.inline))
        default:
            HomeView()
        }
    }

    /// ホームから1画面進んだ状態（戻るボタンつき）で見せる
    private static func pushed<V: View>(_ v: V) -> some View {
        NavigationStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
                .navigationTitle(APP_TITLE)
                .navigationDestination(isPresented: .constant(true)) { v }
        }
    }

    /// 見本の解答：先頭から n 問に答え、9問に1問はわざと外す（記述式は答えない）
    private static func answers(_ round: ExamRound, upTo n: Int) -> ([String: Set<Int>], [String: String]) {
        var sel: [String: Set<Int>] = [:], typed: [String: String] = [:]
        for (i, q) in round.sections.flatMap({ $0.questions }).enumerated() where i < n {
            let miss = i % 9 == 4
            switch q.kind {
            case .choice:
                guard let a = q.answer else { continue }
                let k = max(q.choices?.count ?? 0, 1)
                sel[q.label] = miss ? [a % max(k, 2) + 1] : [a]
            case .multi:
                sel[q.label] = miss ? Set(q.answerSet.prefix(1)) : q.answerSet
            case .input:
                typed[q.label] = miss ? "—" : (q.accepted?.first ?? "")
            case .write:
                continue
            }
        }
        return (sel, typed)
    }

    /// ExamView.finish と同じ計算で受験記録をつくる（記述式は満点の約7割を自己採点したことにする）
    private static func record(_ round: ExamRound, _ sel: [String: Set<Int>], _ typed: [String: String], date: Date) -> ExamRecord {
        let subjects = round.sections.map { sec -> SubjectScore in
            let score = sec.questions.reduce(0.0) { acc, q in
                switch q.kind {
                case .write: return acc + (q.points * 0.7).rounded()
                case .input: return acc + q.scoreTyped(typed[q.label] ?? "")
                default:     return acc + q.score(selected: sel[q.label] ?? [])
                }
            }
            return SubjectScore(title: sec.title, score: Int(score.rounded()), max: Int(sec.maxPoints.rounded()))
        }
        return ExamRecord(id: UUID(), date: date, levelKey: level.key, round: round.round,
                          subjects: subjects, passing: round.passing)
    }

    /// 受験履歴の見本（第1回に2件・第2回に1件）。撮影のたびに入れ直す
    private static func seedRecords() {
        UserDefaults.standard.removeObject(forKey: RECORD_KEY)
        let cal = Calendar.current, now = Date()
        func day(_ d: Int, _ h: Int, _ m: Int) -> Date {
            cal.date(bySettingHour: h, minute: m, second: 0, of: cal.date(byAdding: .day, value: -d, to: now)!)!
        }
        let rounds = level.rounds
        let (all, allTyped) = answers(rounds[0], upTo: Int.max)
        RecordStore.shared.add(record(rounds[0], all, allTyped, date: day(1, 21, 14)))
        let (part, partTyped) = answers(rounds[0], upTo: rounds[0].questionCount * 2 / 3)
        RecordStore.shared.add(record(rounds[0], part, partTyped, date: day(6, 20, 2)))
        if rounds.count > 1 {
            let (a2, t2) = answers(rounds[1], upTo: Int.max)
            RecordStore.shared.add(record(rounds[1], a2, t2, date: day(3, 19, 40)))
        }
    }
}
#endif
