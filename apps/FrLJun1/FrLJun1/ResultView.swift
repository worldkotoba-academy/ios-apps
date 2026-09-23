import SwiftUI

// MARK: - 採点結果と復習

struct ResultView: View {
    let level: ExamLevel
    let round: ExamRound
    let answers: [String: Int]
    let typed: [String: String]
    let record: ExamRecord

    @State private var showReview = false

    /// 選択式でまちがえた問題（記述式は自己採点なので復習一覧には出さない）
    private var wrong: [(ExamSection, ExamQuestion)] {
        round.sections.filter { $0.type != .write }.flatMap { sec in
            sec.questions.filter { answers[$0.label] != $0.answer }.map { (sec, $0) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalCard
                sectionCard
                reviewCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var totalCard: some View {
        VStack(spacing: 6) {
            Text("\(record.total)")
                .font(.system(size: 68, weight: .bold)).foregroundColor(.frBlue).monospacedDigit()
            Text("/ \(record.totalMax)点　得点の目安 \(round.passing)点")
                .font(.footnote).foregroundColor(.secondary)
            Text(record.reached ? "目安に到達" : "あと \(max(0, round.passing - record.total)) 点")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background((record.reached ? Color.green : Color.frRed).opacity(0.18))
                .foregroundColor(record.reached ? .green : .frRed)
                .clipShape(Capsule()).padding(.top, 4)
            Text(level.official).font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 22).frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("大問ごとの得点").font(.headline)
            ForEach(record.subjects) { s in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(s.title).font(.footnote).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Text("\(s.score) / \(s.max)点").font(.footnote.weight(.bold))
                            .foregroundColor(s.ratio >= 0.6 ? .green : .frRed).fixedSize()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.tertiarySystemGroupedBackground))
                            Capsule().fill(s.ratio >= 0.6 ? Color.green : Color.frRed)
                                .frame(width: geo.size.width * s.ratio)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("まちがえた問題（\(wrong.count)問）").font(.headline)
                Spacer()
                if !wrong.isEmpty {
                    Button(showReview ? "閉じる" : "復習する") {
                        withAnimation(.easeInOut(duration: 0.15)) { showReview.toggle() }
                    }
                    .font(.footnote.weight(.semibold)).foregroundColor(.frBlue)
                }
            }
            if wrong.isEmpty {
                Text("選択式は全問正解です。おつかれさまでした。")
                    .font(.footnote).foregroundColor(.secondary)
            } else if !showReview {
                Text("解説と読み上げつきで見直せます。").font(.footnote).foregroundColor(.secondary)
            }
            if showReview {
                ForEach(wrong.indices, id: \.self) { i in
                    let (sec, q) = wrong[i]
                    VStack(alignment: .leading, spacing: 6) {
                        Text("大問\(sec.no)　\(sec.title)")
                            .font(.caption.weight(.bold)).foregroundColor(.frBlue)
                        // 同じ大問の本文・共有選択肢は最初の1問にだけ付ける
                        if i == 0 || wrong[i - 1].0.no != sec.no {
                            if sec.hasContext { ContextCard(section: sec) }
                            if sec.showsSharedChoices { SharedChoicesCard(section: sec) }
                        }
                        QuestionCard(section: sec, q: q,
                                     selection: .constant(answers[q.label] ?? -1),
                                     typed: .constant(typed[q.label] ?? ""),
                                     reveal: true)
                    }
                }
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
