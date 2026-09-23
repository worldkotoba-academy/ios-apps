import SwiftUI

// MARK: - 大問の本文（長文・会話文・掲示・挿絵）

struct ContextCard: View {
    let section: ExamSection
    @State private var expanded = true
    @State private var showTranslation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(section.contextTitle ?? "本文").font(.caption.weight(.bold)).foregroundColor(.exAccent)
                Spacer()
                if let ctx = section.context, !ctx.isEmpty, isTargetLanguage(ctx) {
                    SpeakButtons(text: ctx, idKey: "ctx-\(section.no)", compact: true)
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold)).foregroundColor(.exAccent)
                }
                .buttonStyle(.plain)
            }
            if expanded {
                if let name = section.image, let ui = loadImage(name) {
                    Image(uiImage: ui).resizable().scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                if let ctx = section.context, !ctx.isEmpty {
                    Text(ctx).font(contentFont(.callout, 16)).lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let src = section.contextSource, !src.isEmpty {
                    Text(src).font(.caption2).foregroundColor(.secondary)
                }
                if let tr = section.contextTranslation, !tr.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { showTranslation.toggle() }
                    } label: {
                        Label(showTranslation ? "和訳を隠す" : "和訳を見る",
                              systemImage: showTranslation ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold)).foregroundColor(.exRed)
                    }
                    .buttonStyle(.plain)
                    if showTranslation {
                        Text(tr).font(.footnote).foregroundColor(.secondary).lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.exGold.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func loadImage(_ name: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

// MARK: - 統計グラフ

struct ChartCard: View {
    let chart: ChartSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chart.title).font(.caption.weight(.bold)).foregroundColor(.exAccent)
                .fixedSize(horizontal: false, vertical: true)
            let maxV = chart.max ?? (chart.values.max() ?? 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(chart.categories.enumerated()), id: \.offset) { i, cat in
                    let v = i < chart.values.count ? chart.values[i] : 0
                    VStack(spacing: 4) {
                        Text("\(pts(v))\(chart.unit ?? "")").font(.caption2.weight(.semibold))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.exRed)
                            .frame(height: Swift.max(4, 120 * v / Swift.max(maxV, 1)))
                        Text(cat).font(.caption2).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 175, alignment: .bottom)
            if let s = chart.source, !s.isEmpty {
                Text(s).font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 大問共通の選択肢

struct SharedChoicesCard: View {
    let section: ExamSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.sharedChoicesTitle ?? "選択肢").font(.caption.weight(.bold)).foregroundColor(.exAccent)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(section.sharedChoices.enumerated()), id: \.offset) { i, c in
                    HStack(alignment: .top, spacing: 8) {
                        Text(mark(i + 1)).font(.footnote.weight(.bold))
                        Text(c).font(contentFont(.footnote, 13)).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - *強調* を下線＋太字で描く

struct MarkedText: View {
    let raw: String
    var prefix: String = ""
    init(_ raw: String, prefix: String = "") { self.raw = raw; self.prefix = prefix }

    var body: some View {
        Text(attributed).fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        var out = AttributedString(prefix)
        for (i, part) in raw.components(separatedBy: "*").enumerated() {
            var a = AttributedString(part)
            if i % 2 == 1 {
                a.underlineStyle = .single
                a.inlinePresentationIntent = .stronglyEmphasized
            }
            out.append(a)
        }
        return out
    }
}

// MARK: - 設問カード

struct QuestionCard: View {
    let section: ExamSection
    let q: ExamQuestion
    /// 選んだ番号の集合（choice は高々1つ）
    @Binding var selected: Set<Int>
    /// 記述・短答の入力
    @Binding var typed: String
    /// 解説を出すか
    let reveal: Bool

    private var answered: Bool {
        switch q.kind {
        case .choice: return !selected.isEmpty
        case .multi:  return selected.count >= (q.numSelect ?? 1)
        case .write:  return true
        case .input:  return !typed.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    private var showFeedback: Bool { reveal && answered }
    private var correct: Bool {
        switch q.kind {
        case .choice: return selected == [q.answer ?? -1]
        case .multi:  return selected == q.answerSet
        case .input:  return q.matches(typed)
        case .write:  return false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(q.label).font(.caption.weight(.bold)).foregroundColor(.secondary)
                Spacer()
                Text("\(pts(q.points))点").font(.caption2).foregroundColor(.secondary)
            }
            if let h = q.hint, !h.isEmpty {
                Text(h).font(.footnote).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let p = q.prompt, !p.isEmpty {
                MarkedText(p).font(contentFont(.body, 17, .medium))
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if !q.stem.isEmpty {
                MarkedText(q.stem).font(contentFont(.title3, 20, .medium))
            }
            if q.kind == .multi, let n = q.numSelect {
                Text("\(n) つ選ぶ" + (q.scoring == "all" ? "（全部正解で得点）" : "（1つ正解ごとに得点）"))
                    .font(.caption.weight(.semibold)).foregroundColor(.exRed)
            }

            switch q.kind {
            case .write: writeField
            case .input: inputField
            default:     choiceList
            }

            if showFeedback { feedback }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 選択肢

    private var choiceList: some View {
        let list = section.choices(for: q)
        return VStack(spacing: 8) {
            ForEach(Array(list.enumerated()), id: \.offset) { idx, choice in
                choiceButton(idx + 1, choice)
            }
        }
    }

    private func choiceButton(_ i: Int, _ choice: String) -> some View {
        let isSel = selected.contains(i)
        let isAns = q.kind == .choice ? (q.answer == i) : q.answerSet.contains(i)
        var bg = Color(.tertiarySystemGroupedBackground)
        var fg = Color.primary
        if showFeedback {
            if isAns { bg = Color.green.opacity(0.18) }
            if isSel && !isAns { bg = Color.exRed.opacity(0.15); fg = .exRed }
        } else if isSel {
            bg = Color.exGold.opacity(0.35)
        }
        return Button {
            if q.kind == .choice {
                selected = [i]
            } else if isSel {
                selected.remove(i)
            } else if selected.count < (q.numSelect ?? Int.max) {
                selected.insert(i)
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(mark(i)).font(.body.weight(.semibold))
                Text(choice).font(contentFont(.body, 17)).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if showFeedback && isAns { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                if showFeedback && isSel && !isAns { Image(systemName: "xmark.circle.fill").foregroundColor(.exRed) }
                if !showFeedback && q.kind == .multi && isSel { Image(systemName: "checkmark.square.fill").foregroundColor(.exAccent) }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg).foregroundColor(fg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: 記述（自己採点）

    private var writeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("解答を入力").font(.caption.weight(.bold)).foregroundColor(.exAccent)
                Spacer()
                Text("\(typed.count) 字").font(.caption2).foregroundColor(.secondary).monospacedDigit()
            }
            TextField("", text: $typed, axis: .vertical)
                .lineLimit(4...18)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: 短答（自動採点）

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("解答を入力（自動採点）").font(.caption.weight(.bold)).foregroundColor(.exAccent)
            TextField("", text: $typed)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .background(showFeedback ? (correct ? Color.green.opacity(0.15) : Color.exRed.opacity(0.12))
                                         : Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: フィードバック

    @ViewBuilder
    private var feedback: some View {
        VStack(alignment: .leading, spacing: 10) {
            if q.kind == .write {
                VStack(alignment: .leading, spacing: 6) {
                    Text("解答例").font(.caption.weight(.bold)).foregroundColor(.exAccent)
                    Text(q.answerText ?? "").font(contentFont(.body, 17, .medium))
                        .fixedSize(horizontal: false, vertical: true)
                    if let tr = q.translation, !tr.isEmpty {
                        Text(tr).font(.footnote).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let sp = spokenText { SpeakButtons(text: sp, idKey: q.label) }
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.exGold.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                let ansText: String = {
                    switch q.kind {
                    case .choice: return mark(q.answer ?? 0)
                    case .multi:  return q.answerSet.sorted().map(mark).joined()
                    default:      return (q.accepted?.first ?? q.answerText ?? "")
                    }
                }()
                Label(correct ? "正解！" : "不正解　正答は \(ansText)",
                      systemImage: correct ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(correct ? .green : .exRed)
                    .fixedSize(horizontal: false, vertical: true)

                if q.kind == .input, let acc = q.accepted, acc.count > 1 {
                    Text("他に受け付ける解答：" + acc.dropFirst().joined(separator: " / "))
                        .font(.caption).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let sp = spokenText {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sp).font(contentFont(.body, 17, .medium)).fixedSize(horizontal: false, vertical: true)
                        if let tr = q.translation, !tr.isEmpty {
                            Text(tr).font(.footnote).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        SpeakButtons(text: sp, idKey: q.label)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.exGold.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let tr = q.translation, !tr.isEmpty {
                    Text(tr).font(.footnote).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if q.kind == .multi, let notes = q.choiceNotes {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(notes.enumerated()), id: \.offset) { i, n in
                            HStack(alignment: .top, spacing: 6) {
                                Text(mark(i + 1)).font(.caption.weight(.bold))
                                Text(n).font(.caption).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            if let ex = q.explanation, !ex.isEmpty {
                Text(ex).font(.footnote).foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// 読み上げる学習言語の文。spoken があればそれを使う。
    private var spokenText: String? {
        if let s = q.spoken, !s.isEmpty, isTargetLanguage(s) { return s }
        if q.kind == .write, let a = q.answerText, isTargetLanguage(a) { return a }
        return nil
    }
}
