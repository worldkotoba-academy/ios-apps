import SwiftUI

// MARK: - 単語の詳細（前後にめくれる）

struct WordDetailView: View {
    let words: [VocabWord]
    @State var index: Int
    @ObservedObject private var store = Store.shared

    private var word: VocabWord { words[min(max(index, 0), words.count - 1)] }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    card
                    exampleCard
                    marks
                }
                .padding(16)
            }
            pager
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(index + 1) / \(words.count)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: index) { _, _ in SpeechPlayer.shared.stop() }
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(word.pos).font(.caption.weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(posColor(word.posGroup).opacity(0.16))
                    .foregroundColor(posColor(word.posGroup))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
                Text("No.\(word.no)").font(.caption2).foregroundColor(.secondary)
            }
            Text(word.word).font(contentFont(34, .bold, relativeTo: .largeTitle))
                .fixedSize(horizontal: false, vertical: true)
            Text(word.kana).font(.subheadline).foregroundColor(.secondary)
            SpeakButton(text: word.word, key: "w-\(word.id)")
            Divider()
            Text(word.meaning).font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            if let note = word.note, !note.isEmpty {
                Text(note).font(.footnote).foregroundColor(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var exampleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("例文").font(.caption.weight(.bold)).foregroundColor(.vcAccent)
            Text(word.example).font(contentFont(17, .regular)).fixedSize(horizontal: false, vertical: true)
            Text(word.exampleJa).font(.footnote).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                SpeakButton(text: word.example, key: "e-\(word.id)")
                SpeakButton(text: word.example, key: "es-\(word.id)", slow: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vcGold.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var marks: some View {
        HStack(spacing: 10) {
            MarkButton(title: store.isKnown(word.id) ? "覚えた" : "覚えた にする",
                       icon: "checkmark.circle.fill", on: store.isKnown(word.id), color: .green) {
                store.toggleKnown(word.id)
            }
            MarkButton(title: "苦手", icon: "exclamationmark.circle.fill",
                       on: store.isWeak(word.id), color: .vcRed) { store.toggleWeak(word.id) }
            MarkButton(title: "お気に入り", icon: "star.fill",
                       on: store.isFavorite(word.id), color: .vcGold) { store.toggleFavorite(word.id) }
        }
    }

    private var pager: some View {
        HStack {
            Button { if index > 0 { index -= 1 } } label: {
                Image(systemName: "chevron.left.circle.fill").font(.title)
            }
            .disabled(index == 0)
            Spacer()
            Text("\(index + 1) / \(words.count)").font(.subheadline.weight(.semibold)).monospacedDigit()
            Spacer()
            Button { if index < words.count - 1 { index += 1 } } label: {
                Image(systemName: "chevron.right.circle.fill").font(.title)
            }
            .disabled(index >= words.count - 1)
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

struct MarkButton: View {
    let title: String
    let icon: String
    let on: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2.weight(.semibold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(on ? color.opacity(0.18) : Color(.secondarySystemGroupedBackground))
            .foregroundColor(on ? color : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
