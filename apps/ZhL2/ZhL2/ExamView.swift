import SwiftUI

// MARK: - 本番モード（制限時間つき通し受験 → 選択式・短答は自動採点／記述式は自己採点）

struct ExamView: View {
    let level: ExamLevel
    let round: ExamRound

    private enum Phase { case start, exam, scoring, result }

    @State private var phase: Phase = .start
    @State private var sectionIndex = 0
    @State private var selections: [String: Set<Int>] = [:]
    @State private var typed: [String: String] = [:]
    @State private var selfScores: [String: Double] = [:]
    @State private var remaining = 0
    @State private var showConfirm = false
    @State private var record: ExamRecord? = nil

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var section: ExamSection { round.sections[sectionIndex] }

    private var answeredCount: Int {
        round.sections.flatMap { s in s.questions }.filter { q in
            switch q.kind {
            case .write, .input: return !(typed[q.label] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
            case .choice:        return !(selections[q.label] ?? []).isEmpty
            case .multi:         return (selections[q.label] ?? []).count >= (q.numSelect ?? 1)
            }
        }.count
    }

    var body: some View {
        Group {
            switch phase {
            case .start:   startScreen
            case .exam:    examBody
            case .scoring: ScoringView(round: round, typed: typed, selfScores: $selfScores) { finish() }
            case .result:  if let rec = record {
                ResultView(level: level, round: round, selections: selections, typed: typed, record: rec)
            }
            }
        }
        .navigationTitle("\(LEVEL_DISPLAY) 第\(round.round)回　本番")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(tick) { _ in
            guard phase == .exam else { return }
            if remaining > 0 { remaining -= 1 } else { submit() }
        }
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var startScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("\(round.durationMin)分").font(.system(size: 56, weight: .bold)).foregroundColor(.exAccent)
                    Text("\(round.questionCount)問・\(round.totalPoints)点満点").font(.subheadline).foregroundColor(.secondary)
                    Text("得点の目安 \(round.passing)点").font(.footnote.weight(.semibold)).foregroundColor(.exRed)
                }
                .padding(.vertical, 24).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Label("開始すると時間の計測が始まります", systemImage: "timer")
                    Label("時間切れになるとその時点で採点に進みます", systemImage: "clock.badge.exclamationmark")
                    if round.hasWritten {
                        Label("記述式は解答例と見比べて自己採点します", systemImage: "square.and.pencil")
                    }
                }
                .font(.footnote).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading).padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    remaining = round.durationMin * 60
                    phase = .exam
                } label: {
                    Text("開始する").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.exAccent).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var examBody: some View {
        VStack(spacing: 0) {
            timerBar
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title).font(.caption.weight(.bold)).foregroundColor(.exAccent)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(section.instruction).font(.caption).foregroundColor(.secondary)
                            .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                    }
                    if section.hasContext { ContextCard(section: section) }
                    if let ch = section.chart { ChartCard(chart: ch) }
                    if section.layout == .match { SharedChoicesCard(section: section) }
                    ForEach(section.questions) { q in
                        QuestionCard(section: section, q: q, selected: selBinding(q), typed: txtBinding(q), reveal: false)
                    }
                    navButtons
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("採点しますか？", isPresented: $showConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("採点する") { submit() }
        } message: {
            Text("未解答が \(round.questionCount - answeredCount) 問あります。")
        }
    }

    private var timerBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text(String(format: "残り %02d:%02d", remaining / 60, remaining % 60))
                    .font(.title2.weight(.bold)).monospacedDigit()
                    .foregroundColor(remaining <= 300 ? .exRed : .primary)
                Spacer()
                Text("解答済み \(answeredCount) / \(round.questionCount)")
                    .font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            ProgressView(value: Double(answeredCount), total: Double(round.questionCount)).tint(.exRed)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var navButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { if sectionIndex > 0 { sectionIndex -= 1 } } label: {
                    Text("前へ").frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).disabled(sectionIndex == 0)
                Button { if sectionIndex < round.sections.count - 1 { sectionIndex += 1 } } label: {
                    Text("次へ").frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.exAccent).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).disabled(sectionIndex == round.sections.count - 1)
            }
            Button {
                if answeredCount < round.questionCount { showConfirm = true } else { submit() }
            } label: {
                Text(round.hasWritten ? "解答を終えて採点へ" : "採点する").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.exRed).foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline.weight(.semibold)).padding(.top, 4)
    }

    private func selBinding(_ q: ExamQuestion) -> Binding<Set<Int>> {
        Binding(get: { selections[q.label] ?? [] }, set: { selections[q.label] = $0 })
    }
    private func txtBinding(_ q: ExamQuestion) -> Binding<String> {
        Binding(get: { typed[q.label] ?? "" }, set: { typed[q.label] = $0 })
    }

    private func submit() {
        SpeechPlayer.shared.stop()
        if round.hasWritten {
            for (_, q) in round.writtenQuestions where selfScores[q.label] == nil { selfScores[q.label] = 0 }
            phase = .scoring
        } else {
            finish()
        }
    }

    private func finish() {
        let subjects = round.sections.map { sec -> SubjectScore in
            let score = sec.questions.reduce(0.0) { acc, q in
                switch q.kind {
                case .write: return acc + (selfScores[q.label] ?? 0)
                case .input: return acc + q.scoreTyped(typed[q.label] ?? "")
                default:     return acc + q.score(selected: selections[q.label] ?? [])
                }
            }
            return SubjectScore(title: sec.title, score: Int(score.rounded()), max: Int(sec.maxPoints.rounded()))
        }
        let rec = ExamRecord(id: UUID(), date: Date(), levelKey: level.key,
                             round: round.round, subjects: subjects, passing: round.passing)
        RecordStore.shared.add(rec)
        record = rec
        phase = .result
    }
}
