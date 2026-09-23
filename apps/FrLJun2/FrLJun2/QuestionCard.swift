import SwiftUI

// MARK: - 大問の読み物（長文・会話文・ニュース記事）

struct ContextCard: View {
    let section: ExamSection
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("本文").font(.caption.weight(.bold)).foregroundColor(.frBlue)
                Spacer()
                SpeakButtons(text: section.context ?? "", idKey: "ctx-\(section.no)", compact: true)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold)).foregroundColor(.frBlue)
                }
                .buttonStyle(.plain)
            }
            if expanded {
                Text(section.context ?? "")
                    .font(.callout).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.frBlue.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 大問で共有する選択肢（同じ語は1度だけ）

struct SharedChoicesCard: View {
    let section: ExamSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.type == .write ? "語群（必要に応じて形を変えて使います）"
                                         : "選択肢（各語は1度だけ使えます）")
                .font(.caption.weight(.bold)).foregroundColor(.frBlue)
            FlowRow(spacing: 8) {
                ForEach(Array(section.sharedChoices.enumerated()), id: \.offset) { i, c in
                    Text(section.type == .write ? c : "\(circled(i + 1)) \(c)")
                        .font(.footnote)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 折り返す横並び（選択肢バッジ用）
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return CGSize(width: maxW == .infinity ? x : maxW, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
    }
}

// MARK: - 設問カード

struct QuestionCard: View {
    let section: ExamSection
    let q: ExamQuestion
    /// 選択問題の選んだ番号（1始まり）
    @Binding var selection: Int?
    /// 記述式に入力した解答
    @Binding var typed: String
    /// 解説を出すか（学習モード＝解答後／本番モード＝出さない）
    let reveal: Bool

    private var answered: Bool { selection != nil }
    private var correct: Bool { selection == q.answer }
    private var showFeedback: Bool { reveal && (section.type == .write || answered) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(q.label).font(.caption.weight(.bold)).foregroundColor(.secondary)

            if let p = q.prompt, !p.isEmpty {
                MarkedText(p)
                    .font(.body.weight(.medium))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if !q.stem.isEmpty {
                MarkedText(q.stem)
                    .font(.title3.weight(.medium))
            }

            switch section.type {
            case .illust:  illustChoices
            case .write:   writeField
            default:       textChoices
            }

            if showFeedback { feedback }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: 選択肢

    private var textChoices: some View {
        let list = section.choices(for: q)
        return VStack(spacing: 8) {
            ForEach(Array(list.enumerated()), id: \.offset) { idx, choice in
                choiceButton(idx + 1, choice)
            }
        }
    }

    private func choiceButton(_ i: Int, _ choice: String) -> some View {
        let isSel = selection == i
        let isAns = q.answer == i
        var bg = Color(.tertiarySystemGroupedBackground)
        var fg = Color.primary
        if showFeedback {
            if isAns { bg = Color.green.opacity(0.18) }
            if isSel && !isAns { bg = Color.frRed.opacity(0.15); fg = .frRed }
        } else if isSel {
            bg = Color.frBlue.opacity(0.18)
        }
        return Button { selection = i } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(circled(i)).font(.body.weight(.semibold))
                Text(choice).font(.body).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if showFeedback && isAns { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                if showFeedback && isSel && !isAns { Image(systemName: "xmark.circle.fill").foregroundColor(.frRed) }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg).foregroundColor(fg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    /// 絵の2択。日本語ラベルは答えになるので選ぶ前は出さない（紙の問題冊子と同じ）
    private var illustChoices: some View {
        let scenes = q.scenes ?? []
        return HStack(spacing: 12) {
            ForEach(Array(scenes.enumerated()), id: \.offset) { idx, name in
                let i = idx + 1
                let isSel = selection == i
                let isAns = q.answer == i
                Button { selection = i } label: {
                    VStack(spacing: 6) {
                        Text(circled(i)).font(.subheadline.weight(.bold))
                        Image(name)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        if showFeedback, idx < (q.choices ?? []).count {
                            Text(q.choices![idx]).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(showFeedback
                                ? (isAns ? Color.green.opacity(0.18)
                                         : (isSel ? Color.frRed.opacity(0.15) : Color(.tertiarySystemGroupedBackground)))
                                : (isSel ? Color.frBlue.opacity(0.18) : Color(.tertiarySystemGroupedBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSel ? Color.frBlue : .clear, lineWidth: 2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("選択肢\(circled(i))の絵")
            }
        }
    }

    // MARK: 記述式

    private var writeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("解答を入力").font(.caption.weight(.bold)).foregroundColor(.frBlue)
                Spacer()
                if let n = q.charLimit { Text("\(typed.count) / \(n)字")
                    .font(.caption2)
                    .foregroundColor(typed.count > n ? .frRed : .secondary) }
            }
            TextField("", text: $typed, axis: .vertical)
                .lineLimit(2...8)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: フィードバック

    @ViewBuilder
    private var feedback: some View {
        VStack(alignment: .leading, spacing: 10) {
            if section.type == .write {
                VStack(alignment: .leading, spacing: 6) {
                    Text("解答例").font(.caption.weight(.bold)).foregroundColor(.frBlue)
                    Text(q.answerText ?? "")
                        .font(.body.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    if isFrench(q.answerText ?? "") {
                        SpeakButtons(text: q.answerText ?? "", idKey: q.label)
                    }
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.frBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Label(correct ? "正解！" : "不正解　正答は \(circled(q.answer ?? 0))",
                      systemImage: correct ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(correct ? .green : .frRed)

                let spoken = spokenText
                if !spoken.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(spoken).font(.body.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                        if let tr = q.translation, !tr.isEmpty {
                            Text(tr).font(.footnote).foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        SpeakButtons(text: spoken, idKey: q.label)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.frBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let tr = q.translation, !tr.isEmpty {
                    Text(tr).font(.footnote).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let ex = q.explanation, !ex.isEmpty {
                Text(ex).font(.footnote).foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// 正答を入れた文（フランス語）。日本語しか無い設問は読み上げない。
    private var spokenText: String {
        guard section.type != .illust, section.type != .truefalse else { return "" }
        let list = section.choices(for: q)
        guard let a = q.answer, a >= 1, a <= list.count else { return "" }
        let ans = list[a - 1]
        // 設問文のうちフランス語の行だけを使う（和訳や [regarder / 複合過去] のヒントは読まない）。
        // 言い換え問題（A: … / B: …）は空所のある B 文だけを読む。
        var lines = q.stem.components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: #"\[[^\]]*\]"#, with: "", options: .regularExpression) }
            .map { $0.replacingOccurrences(of: #"^[AB]\s*[:：]\s*"#, with: "", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { isFrench($0) }
        if q.stem.range(of: #"^A\s*[:：]"#, options: .regularExpression) != nil, lines.count >= 2 {
            lines = [lines.last!]
        }
        let french = lines.joined(separator: " ")
        var candidates: [String] = []
        if french.range(of: #"[（(]\s*\d*\s*[）)]"#, options: .regularExpression) != nil {
            candidates.append(fill(french, with: ans))
        }
        candidates.append(ans)
        candidates.append(french)
        return candidates.first(where: isFrench) ?? ""
    }

    /// ラテン文字を含み、かな・漢字を含まない
    private func isFrench(_ s: String) -> Bool {
        var latin = 0
        for u in s.unicodeScalars {
            switch u.value {
            case 0x3040...0x30FF, 0x4E00...0x9FFF, 0xFF66...0xFF9F: return false
            case 0x41...0x5A, 0x61...0x7A, 0xC0...0x24F: latin += 1
            default: break
            }
        }
        return latin >= 2
    }

    private func fill(_ sentence: String, with word: String) -> String {
        guard !word.isEmpty else { return sentence }
        let num = q.label.filter { $0.isNumber }
        if !num.isEmpty,
           let r = sentence.range(of: #"[（(]\s*"# + num + #"\s*[）)]"#, options: .regularExpression) {
            return sentence.replacingCharacters(in: r, with: word)
        }
        if let r = sentence.range(of: #"[（(]\s*\d*\s*[）)]"#, options: .regularExpression) {
            return sentence.replacingCharacters(in: r, with: word)
        }
        return sentence
    }
}


// MARK: - *強調* を下線＋太字で描く（名詞化・派生語問題の下線部）

struct MarkedText: View {
    let raw: String
    var prefix: String = ""

    init(_ raw: String, prefix: String = "") {
        self.raw = raw
        self.prefix = prefix
    }

    var body: some View {
        Text(attributed)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributed: AttributedString {
        var out = AttributedString(prefix)
        // *…* を分割して交互に通常／強調にする（改行はそのまま残す）
        let parts = raw.components(separatedBy: "*")
        for (i, part) in parts.enumerated() {
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
