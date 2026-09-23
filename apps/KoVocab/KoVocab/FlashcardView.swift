import SwiftUI

// MARK: - カード学習（めくって覚える）

struct FlashcardView: View {
    let title: String
    let words: [VocabWord]

    @ObservedObject private var store = Store.shared
    @State private var queue: [VocabWord] = []
    @State private var index = 0
    @State private var flipped = false
    @State private var startedWithUnknownOnly = true
    @State private var finished = false

    var body: some View {
        VStack(spacing: 0) {
            if queue.isEmpty {
                setup
            } else if finished || index >= queue.count {
                result
            } else {
                progressBar
                card
                buttons
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("カード学習")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { SpeechPlayer.shared.stop() }
    }

    private var setup: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(title).font(.headline)
                    Text("\(grouped(words.count))語").font(.footnote).foregroundColor(.secondary)
                    Text("カードをタップすると意味が出ます").font(.caption).foregroundColor(.secondary)
                }
                .padding(.vertical, 20).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button { start(unknownOnly: true) } label: {
                    startLabel("未習得だけで学習", "\(unknownCount)語", .vcAccent)
                }
                .buttonStyle(.plain).disabled(unknownCount == 0)
                Button { start(unknownOnly: false) } label: {
                    startLabel("すべての単語で学習", "\(grouped(words.count))語", .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }

    private var unknownCount: Int { words.filter { !store.isKnown($0.id) }.count }

    private func startLabel(_ t: String, _ d: String, _ c: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(t).font(.subheadline.weight(.bold))
                Text(d).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote)
        }
        .padding(16).foregroundColor(c == .secondary ? .primary : c)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func start(unknownOnly: Bool) {
        let base = unknownOnly ? words.filter { !store.isKnown($0.id) } : words
        queue = base.shuffled()
        index = 0; flipped = false; finished = false
        startedWithUnknownOnly = unknownOnly
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(index + 1) / \(queue.count)").font(.caption.weight(.semibold)).monospacedDigit()
                Spacer()
                Button("やめる") { finished = true }.font(.caption.weight(.semibold)).foregroundColor(.vcRed)
            }
            ProgressBar(ratio: Double(index) / Double(max(queue.count, 1)))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    @ViewBuilder
    private var card: some View {
        let w = queue[index]
        ScrollView {
            VStack(spacing: 14) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { flipped.toggle() }
                } label: {
                    VStack(spacing: 12) {
                        Text(w.pos).font(.caption.weight(.bold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(posColor(w.posGroup).opacity(0.16))
                            .foregroundColor(posColor(w.posGroup))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(w.word).font(.system(size: 36, weight: .bold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if flipped {
                            Text(w.kana).font(.subheadline).foregroundColor(.secondary)
                            Divider()
                            Text(w.meaning).font(.title3.weight(.medium))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(w.example).font(.footnote)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(w.exampleJa).font(.caption).foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("タップして意味を見る").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                    .padding(24)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                SpeakButton(text: w.word, key: "fc-\(w.id)")
            }
            .padding(16)
        }
    }

    private var buttons: some View {
        let w = queue[index]
        return HStack(spacing: 10) {
            Button {
                store.markWeak(w.id); next()
            } label: {
                Text("まだ").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.vcRed.opacity(0.15)).foregroundColor(.vcRed)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            Button {
                store.setKnown(w.id, true); next()
            } label: {
                Text("覚えた").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.vcAccent).foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }

    private func next() {
        SpeechPlayer.shared.stop()
        flipped = false
        if index + 1 >= queue.count { finished = true } else { index += 1 }
    }

    private var result: some View {
        let done = store.knownCount(words)
        return ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 48)).foregroundColor(.vcAccent)
                    Text("おつかれさまでした").font(.headline)
                    Text("この範囲で覚えた単語 \(grouped(done)) / \(grouped(words.count))語")
                        .font(.footnote).foregroundColor(.secondary)
                }
                .padding(.vertical, 28).frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                Button { queue = []; finished = false } label: {
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
