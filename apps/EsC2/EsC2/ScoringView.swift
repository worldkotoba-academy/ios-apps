import SwiftUI

// MARK: - 記述式の自己採点

struct ScoringView: View {
    let round: ExamRound
    let typed: [String: String]
    @Binding var selfScores: [String: Double]
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("記述式の自己採点").font(.headline)
                    Text("解答例と評価ポイントを見て、各問の点数を選んでください。選択式・短答は自動で採点済みです。")
                        .font(.footnote).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(Array(round.writtenQuestions.enumerated()), id: \.offset) { _, pair in
                    scoringCard(pair.0, pair.1)
                }
                Button(action: onDone) {
                    Text("採点を確定して結果を見る").font(.headline)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.exAccent).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("自己採点")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private func scoringCard(_ sec: ExamSection, _ q: ExamQuestion) -> some View {
        let maxPts = q.points
        // scoring が "steps:N" なら満点を N 等分した N+1 段階（DELE の作文のバンド 0〜3 など）
        let custom = q.scoring.flatMap { $0.hasPrefix("steps:") ? Int($0.dropFirst(6)) : nil }
        let stepCount = custom ?? (maxPts >= 8 ? 4 : Int(maxPts.rounded()))
        let steps: [Double] = stepCount <= 0 ? [0, maxPts]
            : (0...stepCount).map { Double($0) * maxPts / Double(stepCount) }
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(sec.code)　\(q.label)").font(.caption.weight(.bold)).foregroundColor(.exAccent)
            if let p = q.prompt, !p.isEmpty { MarkedText(p).font(.footnote) }
            if !q.stem.isEmpty { MarkedText(q.stem).font(.footnote) }
            labeled("あなたの解答", typed[q.label]?.isEmpty == false ? typed[q.label]! : "（未解答）", color: .secondary)
            labeled("解答例", q.answerText ?? "", color: .exAccent)
            if let tr = q.translation, !tr.isEmpty { labeled("解答例の訳", tr, color: .secondary) }
            if let ex = q.explanation, !ex.isEmpty {
                Text(ex).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                ForEach(Array(steps.enumerated()), id: \.offset) { _, v in
                    let sel = selfScores[q.label] == v
                    Button { selfScores[q.label] = v } label: {
                        Text(pts(v)).font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(sel ? Color.exAccent : Color(.tertiarySystemGroupedBackground))
                            .foregroundColor(sel ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("満点 \(pts(maxPts))点").font(.caption2).foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func labeled(_ title: String, _ body: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2.weight(.bold)).foregroundColor(color)
            Text(body).font(.footnote).fixedSize(horizontal: false, vertical: true)
        }
    }
}
