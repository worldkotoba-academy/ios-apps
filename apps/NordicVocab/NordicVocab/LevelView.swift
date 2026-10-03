import SwiftUI

// MARK: - 級のトップ（テーマ別パートの一覧）

struct LevelView: View {
    let level: VocabLevel
    @ObservedObject private var store = Store.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                summary
                HStack(spacing: 10) {
                    NavigationLink { FlashcardView(title: level.name, words: level.words) } label: {
                        ActionTile(icon: "rectangle.on.rectangle.angled", title: "カード学習",
                                   detail: "めくって覚える", color: .vcAccent)
                    }
                    .buttonStyle(.plain)
                    NavigationLink { QuizView(title: level.name, words: level.words) } label: {
                        ActionTile(icon: "checkmark.circle", title: "4択テスト",
                                   detail: "10問で力だめし", color: .vcRed)
                    }
                    .buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("テーマ別").font(.headline)
                    ForEach(level.parts) { part in
                        NavigationLink { PartView(level: level, part: part) } label: { PartRow(part: part) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(level.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var summary: some View {
        let done = store.knownCount(level.words)
        let weak = level.words.filter { store.isWeak($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(level.badge).font(.caption.weight(.bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.vcAccent.opacity(0.14)).foregroundColor(.vcAccent)
                    .clipShape(Capsule())
                Spacer()
                Text("\(grouped(level.count))語").font(.footnote).foregroundColor(.secondary)
            }
            Text(level.subtitle).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ProgressBar(ratio: level.count == 0 ? 0 : Double(done) / Double(level.count))
            HStack {
                Text("覚えた \(grouped(done))語").font(.caption.weight(.semibold)).foregroundColor(.vcAccent)
                Spacer()
                if weak > 0 {
                    Text("苦手 \(weak)語").font(.caption.weight(.semibold)).foregroundColor(.vcRed)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ActionTile: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(.white)
                .frame(width: 38, height: 38).background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title).font(.subheadline.weight(.bold))
            Text(detail).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct PartRow: View {
    let part: VocabPart
    @ObservedObject private var store = Store.shared

    var body: some View {
        let done = store.knownCount(part.words)
        HStack(spacing: 14) {
            Text("\(part.no)")
                .font(.headline.weight(.bold)).foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.vcAccent).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(part.title).font(.subheadline.weight(.semibold))
                Text(part.sub).font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressBar(ratio: part.words.isEmpty ? 0 : Double(done) / Double(part.words.count))
                    .frame(height: 5)
                Text("\(done) / \(part.words.count)語").font(.caption2).foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
