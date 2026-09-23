import SwiftUI

// MARK: - 回のホーム（構成・モード選択・受験履歴）

struct RoundHomeView: View {
    let level: ExamLevel
    let round: ExamRound
    @ObservedObject private var store = RecordStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                info
                NavigationLink { StudyView(level: level, round: round) } label: {
                    ModeCard(icon: "book.fill", title: "学習モード",
                             detail: "1問ずつ解いてすぐに解説・音声を確認", color: .frBlue)
                }
                .buttonStyle(.plain)
                NavigationLink { ExamView(level: level, round: round) } label: {
                    ModeCard(icon: "timer", title: "本番モード",
                             detail: "制限時間\(round.durationMin)分・通しで解答して採点", color: .frRed)
                }
                .buttonStyle(.plain)
                history
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(LEVEL_DISPLAY) 第\(round.round)回")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(round.sections) { sec in
                HStack(alignment: .top) {
                    Text("大問\(sec.no)　\(sec.title)").font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text("\(sec.questions.count)問・\(pts(sec.maxPoints))点")
                        .font(.subheadline).foregroundColor(.secondary).fixedSize()
                }
            }
            Divider()
            HStack {
                Text("満点 \(round.totalPoints)点")
                Spacer()
                Text("目安 \(round.passing)点")
            }
            .font(.footnote.weight(.semibold)).foregroundColor(.frBlue)
            Text(level.official)
                .font(.caption2).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if round.hasWritten {
                Label("記述式をふくむため、その分は解答例を見ながらの自己採点です",
                      systemImage: "square.and.pencil")
                    .font(.caption2).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var history: some View {
        let recs = store.records(levelKey: level.key, round: round.round)
        if !recs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("受験履歴").font(.headline)
                ForEach(recs.prefix(10)) { rec in
                    HStack {
                        Text(rec.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("\(rec.total)/\(rec.totalMax)点").font(.caption.weight(.semibold))
                        Text(rec.reached ? "到達" : "未達")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(rec.reached ? .green : .frRed)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).foregroundColor(.white)
                .frame(width: 52, height: 52).background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
