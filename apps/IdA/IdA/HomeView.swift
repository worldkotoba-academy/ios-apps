import SwiftUI

// MARK: - ホーム（単一級・回の一覧）

struct HomeView: View {
    private let level = ExamData.level

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    ForEach(level.rounds) { round in
                        NavigationLink(value: round) { RoundCard(round: round, level: level) }
                            .buttonStyle(.plain)
                    }
                    disclaimerCard
                    NavigationLink { AboutView() } label: {
                        HStack {
                            Label("このアプリについて・著作権表示", systemImage: "info.circle")
                                .font(.footnote.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .foregroundColor(.exAccent).padding(14)
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
            .navigationDestination(for: ExamRound.self) { RoundHomeView(level: level, round: $0) }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            // 国旗の配色（配色そのものはパブリックドメイン）
            flag
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    Text(LEVEL_DISPLAY)
                        .font(.subheadline.weight(.bold)).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Color.exAccent.opacity(0.92)).clipShape(Capsule())
                )
            Text(level.subtitle)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("模擬試験 全\(level.rounds.count)回　筆記試験対策（\(level.rounds.first?.totalPoints ?? 0)点満点）")
                .font(.caption2).foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var flag: some View {
        if FLAG_VERTICAL_STRIPES {
            HStack(spacing: 0) { ForEach(FLAG_COLORS.indices, id: \.self) { Rectangle().fill(FLAG_COLORS[$0]) } }
        } else {
            VStack(spacing: 0) { ForEach(FLAG_COLORS.indices, id: \.self) { Rectangle().fill(FLAG_COLORS[$0]) } }
        }
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("非公式教材です", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold)).foregroundColor(.exRed)
            Text(DISCLAIMER_HOME)
                .font(.caption2).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.exRed.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.top, 4)
    }
}

struct RoundCard: View {
    let round: ExamRound
    let level: ExamLevel
    @ObservedObject private var store = RecordStore.shared

    var body: some View {
        HStack(spacing: 14) {
            Text("第\(round.round)回")
                .font(.headline.weight(.bold)).foregroundColor(.white)
                .frame(width: 72, height: 64)
                .background(LinearGradient(colors: [.exAccent, .exAccent.opacity(0.75)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(round.title).font(.subheadline.weight(.semibold))
                Text("\(round.durationMin)分・\(round.questionCount)問・\(round.totalPoints)点満点")
                    .font(.caption2).foregroundColor(.secondary)
                if let best = store.best(levelKey: level.key, round: round.round) {
                    Text("最高 \(best.total)/\(best.totalMax)点　\(best.reached ? "目安に到達" : "あと\(max(0, round.passing - best.total))点")")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(best.reached ? .green : .exRed)
                }
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

// MARK: - このアプリについて（著作権・権利表示）

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(ABOUT_SECTIONS.enumerated()), id: \.offset) { _, s in
                    section(s.0, s.1)
                }
                Text("© 2026 Miyu Okazaki").font(.caption).foregroundColor(.secondary).padding(.top, 4)
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.bold)).foregroundColor(.exAccent)
            Text(body).font(.footnote).foregroundColor(.primary.opacity(0.85))
                .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
        }
    }
}
