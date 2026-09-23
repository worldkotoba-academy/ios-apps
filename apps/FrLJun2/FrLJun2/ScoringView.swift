import SwiftUI

// MARK: - 記述式の自己採点

struct ScoringView: View {
    let round: ExamRound
    let typed: [String: String]
    @Binding var selfScores: [String: Int]
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("記述式の自己採点").font(.headline)
                    Text("解答例と見比べて、各問の点数を選んでください。選択式は自動で採点済みです。")
                        .font(.footnote).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(Array(round.writtenQuestions.enumerated()), id: \.offset) { _, pair in
                    let (sec, q) = pair
                    scoringCard(sec, q)
                }
                Button(action: onDone) {
                    Text("採点を確定して結果を見る").font(.headline)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.frBlue).foregroundColor(.white)
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
        let maxPts = Int(sec.points(for: q).rounded())
        let steps = stride(from: 0, through: maxPts, by: max(1, maxPts / 4)).map { $0 }
        return VStack(alignment: .leading, spacing: 8) {
            Text("大問\(sec.no)　\(q.label)")
                .font(.caption.weight(.bold)).foregroundColor(.frBlue)
            if let p = q.prompt, !p.isEmpty {
                Text(p).font(.footnote).fixedSize(horizontal: false, vertical: true)
            }
            if !q.stem.isEmpty {
                Text(q.stem).font(.footnote).fixedSize(horizontal: false, vertical: true)
            }
            labeled("あなたの解答", typed[q.label]?.isEmpty == false ? typed[q.label]! : "（未解答）",
                    color: .secondary)
            labeled("解答例", q.answerText ?? "", color: .frBlue)
            if let ex = q.explanation, !ex.isEmpty {
                Text(ex).font(.caption).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                ForEach(steps, id: \.self) { v in
                    let sel = selfScores[q.label] == v
                    Button { selfScores[q.label] = v } label: {
                        Text("\(v)").font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(sel ? Color.frBlue : Color(.tertiarySystemGroupedBackground))
                            .foregroundColor(sel ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("満点 \(maxPts)点").font(.caption2).foregroundColor(.secondary)
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
