import SwiftUI

// MARK: - 検索（全級を横断）

struct SearchView: View {
    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [(VocabLevel, [VocabWord])] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 1 else { return [] }
        return Vocab.levels.compactMap { lv in
            let hits = lv.words.filter {
                $0.word.lowercased().contains(q) || $0.kana.contains(q) || $0.meaning.contains(q)
                    || $0.example.lowercased().contains(q)
            }
            return hits.isEmpty ? nil : (lv, Array(hits.prefix(60)))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("スペル・カナ・意味で検索", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if query.isEmpty {
                    Text("見出し語・カナ発音・日本語の意味・例文から探せます")
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center).padding(.top, 20)
                } else if results.isEmpty {
                    Text("見つかりませんでした").font(.footnote).foregroundColor(.secondary).padding(.top, 20)
                } else {
                    ForEach(results, id: \.0.key) { lv, hits in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(lv.name).font(.caption.weight(.bold)).foregroundColor(.vcAccent)
                                Spacer()
                                Text("\(hits.count)件").font(.caption2).foregroundColor(.secondary)
                            }
                            ForEach(hits) { w in
                                NavigationLink { WordDetailView(words: hits, index: hits.firstIndex(of: w) ?? 0) } label: {
                                    WordRow(word: w)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("検索")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
        .onDisappear { SpeechPlayer.shared.stop() }
    }
}
