import SwiftUI

// MARK: - 4択テスト（意味を選ぶ）

struct QuizView: View {
    let title: String
    let words: [VocabWord]

    @ObservedObject private var store = Store.shared
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var picked: Int? = nil
    @State private var correct = 0
    @State private var finished = false

    struct Question: Identifiable {
        let id = UUID()
        let word: VocabWord
        let choices: [String]
        let answer: Int
    }

    private let perRound = 10

    var body: some View {
        VStack(spacing: 0) {
            if questions.isEmpty {
                setup
            } else if finished {
                result
            } else {
                progressBar
                quiz
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("4択テスト")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var setup: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(title).font(.headline)
                    Text("\(grouped(words.count))語から\(min(perRound, words.count))問").font(.footnote).foregroundColor(.secondary)
                    Text("単語の意味を4つの選択肢から選びます").font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                Button { start(pool: words) } label: {
                    startLabel("すべての単語から出題", "\(grouped(words.count))語")
                }
                .buttonStyle(.plain)
                Button { start(pool: words.filter { store.isWeak($0.id) || !store.isKnown($0.id) }) } label: {
                    startLabel("苦手・未習得から出題", "\(words.filter { store.isWeak($0.id) || !store.isKnown($0.id) }.count)語")
                }
                .buttonStyle(.plain)
                .disabled(words.filter { store.isWeak($0.id) || !store.isKnown($0.id) }.isEmpty)
            }
            .padding(16)
        }
    }

    private func startLabel(_ t: String, _ d: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(t).font(.subheadline.weight(.bold))
                Text(d).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func start(pool: [VocabWord]) {
        guard pool.count >= 1 else { return }
        // 誤答の選択肢は同じ級の語彙から取る（無ければ全体から）
        let distractorPool = words.count >= 4 ? words : Vocab.allWords
        let picks = pool.shuffled().prefix(min(perRound, pool.count))
        questions = picks.map { w in
            var opts = [w.meaning]
            var guard_ = 0
            while opts.count < 4 && guard_ < 200 {
                guard_ += 1
                if let c = distractorPool.randomElement(), c.id != w.id, !opts.contains(c.meaning) {
                    opts.append(c.meaning)
                }
            }
            while opts.count < 4 { opts.append("―") }
            let shuffled = opts.shuffled()
            return Question(word: w, choices: shuffled, answer: shuffled.firstIndex(of: w.meaning) ?? 0)
        }
        index = 0; picked = nil; correct = 0; finished = false
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(index + 1) / \(questions.count)").font(.caption.weight(.semibold)).monospacedDigit()
                Spacer()
                Text("正解 \(correct)").font(.caption.weight(.semibold)).foregroundColor(.vcAccent)
            }
            ProgressBar(ratio: Double(index) / Double(max(questions.count, 1)))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    @ViewBuilder
    private var quiz: some View {
        let q = questions[index]
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 10) {
                    Text(q.word.pos).font(.caption.weight(.bold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(posColor(q.word.posGroup).opacity(0.16))
                        .foregroundColor(posColor(q.word.posGroup))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(q.word.word).font(contentFont(32, .bold, relativeTo: .largeTitle))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if picked != nil {
                        Text(q.word.kana).font(.footnote).foregroundColor(.secondary)
                        SpeakButton(text: q.word.word, key: "q-\(q.word.id)")
                    }
                }
                .frame(maxWidth: .infinity).padding(24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 8) {
                    ForEach(q.choices.indices, id: \.self) { i in
                        choiceButton(q, i)
                    }
                }

                if picked != nil {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(q.word.example).font(contentFont(13, .regular, relativeTo: .footnote)).fixedSize(horizontal: false, vertical: true)
                        Text(q.word.exampleJa).font(.caption).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.vcGold.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button { next() } label: {
                        Text(index + 1 >= questions.count ? "結果を見る" : "次の問題")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.vcAccent).foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func choiceButton(_ q: Question, _ i: Int) -> some View {
        var bg = Color(.secondarySystemGroupedBackground)
        var fg = Color.primary
        if let p = picked {
            if i == q.answer { bg = Color.green.opacity(0.18); fg = .green }
            else if i == p { bg = Color.vcRed.opacity(0.15); fg = .vcRed }
        }
        return Button {
            guard picked == nil else { return }
            picked = i
            if i == q.answer { correct += 1; store.setKnown(q.word.id, true) }
            else { store.markWeak(q.word.id) }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text("\(i + 1)").font(.footnote.weight(.bold)).foregroundColor(.secondary)
                Text(q.choices[i]).font(.body).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if picked != nil && i == q.answer { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg).foregroundColor(fg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func next() {
        SpeechPlayer.shared.stop()
        picked = nil
        if index + 1 >= questions.count { finished = true } else { index += 1 }
    }

    private var result: some View {
        let rate = questions.isEmpty ? 0 : Int(Double(correct) / Double(questions.count) * 100)
        return ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    Text("\(correct) / \(questions.count)")
                        .font(.system(size: 52, weight: .bold)).foregroundColor(.vcAccent).monospacedDigit()
                    Text("正答率 \(rate)%").font(.footnote).foregroundColor(.secondary)
                    Text(rate >= 80 ? "よくできました" : "まちがえた単語は「苦手」に入れました")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 28).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                Button { questions = [] } label: {
                    Text("もう一度").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.vcAccent).foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }
}
