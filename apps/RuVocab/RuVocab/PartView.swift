import SwiftUI

// MARK: - パート（テーマ）の単語一覧

struct PartView: View {
    let level: VocabLevel
    let part: VocabPart

    var body: some View {
        WordListView(title: part.title, subtitle: part.sub, words: part.words, showStudyButtons: true)
    }
}

/// 単語の一覧（パート・苦手・お気に入り・検索結果で共通に使う）
struct WordListView: View {
    let title: String
    var subtitle: String? = nil
    let words: [VocabWord]
    var showStudyButtons: Bool = false

    @ObservedObject private var store = Store.shared
    @State private var filter: Filter = .all

    private enum Filter: String, CaseIterable {
        case all = "すべて", unknown = "未習得", known = "覚えた", weak = "苦手", favorite = "お気に入り"
    }

    private var shown: [VocabWord] {
        switch filter {
        case .all:       return words
        case .unknown:   return words.filter { !store.isKnown($0.id) }
        case .known:     return words.filter { store.isKnown($0.id) }
        case .weak:      return words.filter { store.isWeak($0.id) }
        case .favorite:  return words.filter { store.isFavorite($0.id) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let s = subtitle, !s.isEmpty {
                    Text(s).font(.caption).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if showStudyButtons && !words.isEmpty {
                    HStack(spacing: 10) {
                        NavigationLink { FlashcardView(title: title, words: words) } label: {
                            ActionTile(icon: "rectangle.on.rectangle.angled", title: "カード学習",
                                       detail: "\(words.count)語", color: .vcAccent)
                        }
                        .buttonStyle(.plain)
                        NavigationLink { QuizView(title: title, words: words) } label: {
                            ActionTile(icon: "checkmark.circle", title: "4択テスト",
                                       detail: "10問", color: .vcRed)
                        }
                        .buttonStyle(.plain)
                    }
                }
                filterBar
                if shown.isEmpty {
                    Text("該当する単語はありません").font(.footnote).foregroundColor(.secondary)
                        .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(shown) { w in
                            NavigationLink { WordDetailView(words: shown, index: shown.firstIndex(of: w) ?? 0) } label: {
                                WordRow(word: w)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { f in
                    let sel = f == filter
                    Button { filter = f } label: {
                        Text(f.rawValue).font(.caption.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(sel ? Color.vcAccent : Color(.secondarySystemGroupedBackground))
                            .foregroundColor(sel ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

struct WordRow: View {
    let word: VocabWord
    @ObservedObject private var store = Store.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(word.word).font(.body.weight(.semibold))
                    Text(word.pos).font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(posColor(word.posGroup).opacity(0.16))
                        .foregroundColor(posColor(word.posGroup))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Text(word.kana).font(.caption2).foregroundColor(.secondary)
                Text(word.meaning).font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            VStack(spacing: 8) {
                if store.isKnown(word.id) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else if store.isWeak(word.id) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.vcRed)
                }
                if store.isFavorite(word.id) {
                    Image(systemName: "star.fill").foregroundColor(.vcGold).font(.caption)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
