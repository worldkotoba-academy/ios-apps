import SwiftUI

// MARK: - ホーム（単一級・回の一覧）

struct HomeView: View {
    private let level = ExamData.level

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    ForEach(level.rounds) { round in
                        NavigationLink(value: round) { RoundCard(round: round, level: level) }
                            .buttonStyle(.plain)
                    }
                    disclaimerCard
                    NavigationLink { AboutView() } label: {
                        HStack {
                            Label("このアプリについて・著作権表示", systemImage: "info.circle")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .foregroundColor(.frBlue).padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(APP_TITLE)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ExamRound.self) { RoundHomeView(level: level, round: $0) }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            // フランス国旗の青白赤（配色はパブリックドメイン）
            HStack(spacing: 0) {
                Rectangle().fill(Color.frBlue)
                Rectangle().fill(Color.white)
                Rectangle().fill(Color.frRed)
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))
            .overlay(
                Text(LEVEL_DISPLAY)
                    .font(.subheadline.weight(.bold)).foregroundColor(.frBlue)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.white.opacity(0.92)).clipShape(Capsule())
            )
            Text(level.subtitle)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("模擬試験 全\(level.rounds.count)回　筆記試験対策")
                .font(.caption2).foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("非公式教材です", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold)).foregroundColor(.frRed)
            Text("本アプリは個人が独自に作成した学習用の模擬問題集です。実用フランス語技能検定試験を実施する団体とは一切関係がなく、公認・提携・推薦を受けたものではありません。収録した問題・解説はすべて本アプリのために新規に作成したもので、実際の試験問題を転載したものではありません。")
                .font(.caption2).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.frRed.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.top, 4)
    }
}

struct RoundCard: View {
    let round: ExamRound
    let level: ExamLevel
    @ObservedObject private var store = RecordStore.shared

    var body: some View {
        HStack(spacing: 14) {
            Text("第\(round.round)回")
                .font(.headline.weight(.bold)).foregroundColor(.white)
                .frame(width: 72, height: 64)
                .background(LinearGradient(colors: [.frBlue, .frBlue.opacity(0.75)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(round.title).font(.subheadline.weight(.semibold))
                Text("\(round.durationMin)分・\(round.questionCount)問・\(round.totalPoints)点満点")
                    .font(.caption2).foregroundColor(.secondary)
                if let best = store.best(levelKey: level.key, round: round.round) {
                    Text("最高 \(best.total)/\(best.totalMax)点　\(best.reached ? "目安に到達" : "あと\(max(0, round.passing - best.total))点")")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(best.reached ? .green : .frRed)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - このアプリについて（著作権・権利表示）

struct AboutView: View {
    private let level = ExamData.level

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("このアプリについて",
                        "\(APP_TITLE)は、フランス語学習者のための模擬問題集アプリです。全\(level.rounds.count)回の模擬試験を収録し、学習モードでは1問ずつ解説と読み上げを、本番モードでは制限時間つきの通し演習と採点ができます。選択式は自動採点、記述式は解答例と照らし合わせる自己採点です。")

                section("公式試験との関係",
                        "本アプリは個人が独自に制作した非公式の学習教材です。実用フランス語技能検定試験およびその実施団体とは一切関係がなく、公認・提携・監修・推薦を受けたものではありません。出題形式は公開されている一般的な情報を参考にした独自解釈であり、実際の試験の構成・難易度・配点を保証するものではありません。")

                section("聞き取り・書き取りについて",
                        "本試験には聞き取り（および上位級では書き取り）がありますが、本アプリは筆記問題に特化しています。\(level.official)。本アプリの得点の目安は、この基準を本書の配点に当てはめた参考値です。")

                section("問題・解説の著作権",
                        "収録されているすべての問題文・選択肢・和訳・解答例・解説・挿絵は、本アプリのために新規に作成したオリジナルです。過去問題その他の第三者の著作物を転載・翻案したものではありません。これらの著作権は制作者に帰属します。")

                section("音声について",
                        "フランス語の読み上げには、iOS に標準搭載された音声合成機能（AVSpeechSynthesizer）のみを使用しています。第三者が権利を持つ音声データや録音は同梱していません。端末にフランス語音声が入っていない場合は、iOS の「設定 > アクセシビリティ > 読み上げコンテンツ > 声」からフランス語の音声を追加すると読み上げ品質が向上します。")

                section("プライバシー",
                        "本アプリは個人情報を一切収集しません。学習履歴と採点結果は端末内にのみ保存され、外部に送信されることはありません。通信機能・広告・解析ツールを使用していません。")

                section("商標について",
                        "文中の団体名・試験名は各権利者の商標または登録商標です。本アプリでは、対応する学習範囲を説明する目的でのみ言及しています。")

                Text("© 2026 Miyu Okazaki").font(.caption).foregroundColor(.secondary).padding(.top, 4)
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.bold)).foregroundColor(.frBlue)
            Text(body).font(.footnote).foregroundColor(.primary.opacity(0.85))
                .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
        }
    }
}
