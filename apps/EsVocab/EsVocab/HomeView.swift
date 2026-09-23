import SwiftUI

// MARK: - ホーム（級の選択・全体の進捗）

struct HomeView: View {
    @ObservedObject private var store = Store.shared
    @State private var showSearch = false

    private var allWords: [VocabWord] { Vocab.allWords }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    searchButton
                    ForEach(Vocab.levels) { level in
                        NavigationLink(value: level) { LevelCard(level: level) }
                            .buttonStyle(.plain)
                    }
                    quickLists
                    NavigationLink { AboutView() } label: {
                        HStack {
                            Label("このアプリについて・著作権表示", systemImage: "info.circle")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .foregroundColor(.vcAccent).padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16).padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(APP_TITLE)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: VocabLevel.self) { LevelView(level: $0) }
            .navigationDestination(isPresented: $showSearch) { SearchView() }
        }
    }

    private var header: some View {
        let done = store.knownCount(allWords)
        return VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(FLAG_COLORS.indices, id: \.self) { Rectangle().fill(FLAG_COLORS[$0]) }
            }
            .frame(height: 46)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                Text("全\(grouped(allWords.count))語")
                    .font(.subheadline.weight(.bold)).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.vcAccent.opacity(0.92)).clipShape(Capsule())
            )
            VStack(spacing: 6) {
                HStack {
                    Text("覚えた単語").font(.footnote.weight(.semibold))
                    Spacer()
                    Text("\(grouped(done)) / \(grouped(allWords.count))語")
                        .font(.footnote.weight(.bold)).foregroundColor(.vcAccent).monospacedDigit()
                }
                ProgressBar(ratio: allWords.isEmpty ? 0 : Double(done) / Double(allWords.count))
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }

    private var searchButton: some View {
        Button { showSearch = true } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("単語を検索（全\(grouped(allWords.count))語）").font(.subheadline)
                Spacer()
            }
            .foregroundColor(.secondary).padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var quickLists: some View {
        let weak = allWords.filter { store.isWeak($0.id) }
        let fav = allWords.filter { store.isFavorite($0.id) }
        VStack(spacing: 10) {
            NavigationLink { WordListView(title: "苦手な単語", words: weak) } label: {
                QuickRow(icon: "exclamationmark.triangle.fill", color: .vcRed,
                         title: "苦手な単語", count: weak.count)
            }
            .buttonStyle(.plain)
            NavigationLink { WordListView(title: "お気に入り", words: fav) } label: {
                QuickRow(icon: "star.fill", color: .vcGold, title: "お気に入り", count: fav.count)
            }
            .buttonStyle(.plain)
        }
    }
}

struct QuickRow: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 24)
            Text(title).font(.subheadline.weight(.medium))
            Spacer()
            Text("\(count)語").font(.footnote).foregroundColor(.secondary)
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct LevelCard: View {
    let level: VocabLevel
    @ObservedObject private var store = Store.shared

    var body: some View {
        let done = store.knownCount(level.words)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.name).font(.title3.weight(.bold))
                    Text(level.badge).font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.vcAccent.opacity(0.14))
                        .foregroundColor(.vcAccent).clipShape(Capsule())
                }
                Spacer()
                Text("\(grouped(level.count))語").font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            Text(level.subtitle).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ProgressBar(ratio: level.count == 0 ? 0 : Double(done) / Double(level.count))
            HStack {
                Text("\(level.parts.count)テーマ").font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text("覚えた \(grouped(done))語").font(.caption2.weight(.semibold)).foregroundColor(.vcAccent)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ProgressBar: View {
    let ratio: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.tertiarySystemGroupedBackground))
                Capsule().fill(Color.vcAccent)
                    .frame(width: geo.size.width * min(max(ratio, 0), 1))
            }
        }
        .frame(height: 8)
    }
}
