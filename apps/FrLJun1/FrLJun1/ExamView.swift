import SwiftUI

// MARK: - 本番モード（制限時間つき通し受験 → 選択式は自動採点・記述式は自己採点）

struct ExamView: View {
    let level: ExamLevel
    let round: ExamRound

    private enum Phase { case start, exam, scoring, result }

    @State private var phase: Phase = .start
    @State private var sectionIndex = 0
    @State private var answers: [String: Int] = [:]
    @State private var typed: [String: String] = [:]
    @State private var selfScores: [String: Int] = [:]
    @State private var remaining = 0
    @State private var showConfirm = false
    @State private var record: ExamRecord? = nil

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var section: ExamSection { round.sections[sectionIndex] }

    private var answeredCount: Int {
        round.sections.flatMap { s in s.questions.map { (s, $0) } }.filter { (s, q) in
            s.type == .write ? !(typed[q.label] ?? "").isEmpty : answers[q.label] != nil
        }.count
    }

    var body: some View {
        Group {
            switch phase {
            case .start:   startScreen
            case .exam:    examBody
            case .scoring: ScoringView(round: round, typed: typed, selfScores: $selfScores) { finish() }
            case .result:  if let rec = record {
                ResultView(level: level, round: round, answers: answers, typed: typed, record: rec)
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

    // MARK: 開始前

    private var startScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("\(round.durationMin)分")
                        .font(.system(size: 56, weight: .bold)).foregroundColor(.frBlue)
                    Text("\(round.questionCount)問・\(round.totalPoints)点満点")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("得点の目安 \(round.passing)点").font(.footnote.weight(.semibold)).foregroundColor(.frBlue)
                }
                .padding(.vertical, 24).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Label("開始すると時間の計測が始まります", systemImage: "timer")
                    Label("時間切れになるとその時点で採点に進みます", systemImage: "clock.badge.exclamationmark")
                    if round.hasWritten {
                        Label("記述式は解答例と見比べて自己採点します", systemImage: "square.and.pencil")
                    } else {
                        Label("全問マークシート形式なので採点は自動です", systemImage: "checkmark.circle")
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
                        .background(Color.frBlue).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: 受験中

    private var examBody: some View {
        VStack(spacing: 0) {
            timerBar
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("大問\(section.no)　\(section.title)")
                            .font(.caption.weight(.bold)).foregroundColor(.frBlue)
                        Text(section.instruction).font(.caption).foregroundColor(.secondary)
                            .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                        if let ex = section.example, !ex.isEmpty {
                            MarkedText(ex, prefix: "例：").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    if section.hasContext { ContextCard(section: section) }
                    if section.showsSharedChoices { SharedChoicesCard(section: section) }
                    ForEach(section.questions) { q in
                        QuestionCard(section: section, q: q,
                                     selection: selBinding(q), typed: txtBinding(q), reveal: false)
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
                Text(timeString).font(.title2.weight(.bold)).monospacedDigit()
                    .foregroundColor(remaining <= 300 ? .frRed : .primary)
                Spacer()
                Text("解答済み \(answeredCount) / \(round.questionCount)")
                    .font(.caption.weight(.semibold)).foregroundColor(.secondary)
            }
            ProgressView(value: Double(answeredCount), total: Double(round.questionCount)).tint(.frBlue)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var navButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { if sectionIndex > 0 { sectionIndex -= 1 } } label: {
                    Text("前の大問").frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).disabled(sectionIndex == 0)
                Button { if sectionIndex < round.sections.count - 1 { sectionIndex += 1 } } label: {
                    Text("次の大問").frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.frBlue).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain).disabled(sectionIndex == round.sections.count - 1)
            }
            Button {
                if answeredCount < round.questionCount { showConfirm = true } else { submit() }
            } label: {
                Text(round.hasWritten ? "解答を終えて採点へ" : "採点する").font(.headline)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.frRed).foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline.weight(.semibold)).padding(.top, 4)
    }

    private var timeString: String {
        String(format: "残り %02d:%02d", remaining / 60, remaining % 60)
    }

    private func selBinding(_ q: ExamQuestion) -> Binding<Int?> {
        Binding(get: { answers[q.label] }, set: { if let v = $0 { answers[q.label] = v } })
    }
    private func txtBinding(_ q: ExamQuestion) -> Binding<String> {
        Binding(get: { typed[q.label] ?? "" }, set: { typed[q.label] = $0 })
    }

    // MARK: 採点

    private func submit() {
        SpeechPlayer.shared.stop()
        if round.hasWritten {
            for (sec, q) in round.writtenQuestions where selfScores[q.label] == nil {
                selfScores[q.label] = 0
                _ = sec
            }
            phase = .scoring
        } else {
            finish()
        }
    }

    private func finish() {
        let subjects = round.sections.map { sec -> SubjectScore in
            let score = sec.questions.reduce(0.0) { acc, q in
                if sec.type == .write { return acc + Double(selfScores[q.label] ?? 0) }
                return acc + (answers[q.label] == q.answer ? sec.points(for: q) : 0)
            }
            return SubjectScore(title: "大問\(sec.no) \(sec.title)",
                                score: Int(score.rounded()), max: Int(sec.maxPoints.rounded()))
        }
        let rec = ExamRecord(id: UUID(), date: Date(), levelKey: level.key,
                             round: round.round, subjects: subjects, passing: round.passing)
        RecordStore.shared.add(rec)
        record = rec
        phase = .result
    }
}
