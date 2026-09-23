import SwiftUI

// MARK: - 学習モード（1問ずつ・即時フィードバック・音声）

struct StudyView: View {
    let level: ExamLevel
    let round: ExamRound

    @State private var sectionIndex = 0
    @State private var page = 0
    @State private var selections: [String: Set<Int>] = [:]
    @State private var typed: [String: String] = [:]
    @State private var revealed: Set<String> = []

    private var section: ExamSection { round.sections[sectionIndex] }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            TabView(selection: $page) {
                ForEach(section.questions.indices, id: \.self) { qi in
                    let q = section.questions[qi]
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            instructionCard
                            if section.hasContext { ContextCard(section: section) }
                            if let ch = section.chart { ChartCard(chart: ch) }
                            if section.layout == .match { SharedChoicesCard(section: section) }
                            QuestionCard(section: section, q: q,
                                         selected: selBinding(q), typed: txtBinding(q),
                                         reveal: q.kind == .write ? revealed.contains(q.label) : true)
                            if q.kind == .write && !revealed.contains(q.label) {
                                Button { revealed.insert(q.label) } label: {
                                    Text("解答例を見る").font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(Color.exAccent).foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                    .tag(qi)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .id(sectionIndex)
            pager
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(LEVEL_DISPLAY) 第\(round.round)回　学習")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: sectionIndex) { _, _ in page = 0; SpeechPlayer.shared.stop() }
        .onChange(of: page) { _, _ in SpeechPlayer.shared.stop() }
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var sectionPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(round.sections.indices, id: \.self) { i in
                        let sel = i == sectionIndex
                        Button { sectionIndex = i } label: {
                            Text(round.sections[i].code)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(sel ? Color.exAccent : Color(.secondarySystemGroupedBackground))
                                .foregroundColor(sel ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain).id(i)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
            .onChange(of: sectionIndex) { _, v in withAnimation { proxy.scrollTo(v, anchor: .center) } }
        }
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.title)
                .font(.caption.weight(.bold)).foregroundColor(.exAccent)
                .fixedSize(horizontal: false, vertical: true)
            Text(section.instruction).font(.caption).foregroundColor(.secondary)
                .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pager: some View {
        HStack {
            Button { if page > 0 { page -= 1 } } label: {
                Image(systemName: "chevron.left.circle.fill").font(.title)
            }
            .disabled(page == 0)
            Spacer()
            Text("\(page + 1) / \(section.questions.count)")
                .font(.subheadline.weight(.semibold)).monospacedDigit()
            Spacer()
            Button { if page < section.questions.count - 1 { page += 1 } } label: {
                Image(systemName: "chevron.right.circle.fill").font(.title)
            }
            .disabled(page == section.questions.count - 1)
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func selBinding(_ q: ExamQuestion) -> Binding<Set<Int>> {
        Binding(get: { selections[q.label] ?? [] }, set: { selections[q.label] = $0 })
    }
    private func txtBinding(_ q: ExamQuestion) -> Binding<String> {
        Binding(get: { typed[q.label] ?? "" }, set: { typed[q.label] = $0 })
    }
}
