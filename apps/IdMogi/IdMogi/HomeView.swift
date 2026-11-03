import SwiftUI

// MARK: - ホーム（全級の一覧）。1つのアプリに全級を入れ、級ごとに購入する

/// 回を開くときの行き先（級と回の組。ExamRound の同一性は回の番号だけなので級と一緒に持つ）
struct RoundRef: Hashable {
    let level: ExamLevel
    let round: ExamRound
}

struct HomeView: View {
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    ForEach(ExamData.levels) { lv in
                        NavigationLink(value: lv) { LevelCard(level: lv) }
                            .buttonStyle(.plain)
                    }
                    RestoreButton()
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
            .navigationDestination(for: ExamLevel.self) { LevelHomeView(level: $0) }
            .navigationDestination(for: RoundRef.self) { RoundHomeView(level: $0.level, round: $0.round) }
        }
        .storeMessages()
    }

    private var header: some View {
        VStack(spacing: 8) {
            FlagBar(label: HOME_BADGE).frame(height: 52)
            Text(HOME_LEAD)
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
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

/// 国旗の配色の帯（配色そのものはパブリックドメイン）に見出しを重ねる
struct FlagBar: View {
    let label: String

    var body: some View {
        flag
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                Text(label)
                    .font(.subheadline.weight(.bold)).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.exAccent.opacity(0.92)).clipShape(Capsule())
            )
    }

    @ViewBuilder
    private var flag: some View {
        if FLAG_VERTICAL_STRIPES {
            HStack(spacing: 0) { ForEach(FLAG_COLORS.indices, id: \.self) { Rectangle().fill(FLAG_COLORS[$0]) } }
        } else {
            VStack(spacing: 0) { ForEach(FLAG_COLORS.indices, id: \.self) { Rectangle().fill(FLAG_COLORS[$0]) } }
        }
    }
}

/// ホームの級カード
struct LevelCard: View {
    let level: ExamLevel
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        HStack(spacing: 14) {
            Text(level.level)
                .font(.headline.weight(.heavy)).foregroundColor(.white)
                .minimumScaleFactor(0.7).lineLimit(1)
                .frame(width: 72, height: 64)
                .background(LinearGradient(colors: [.exAccent, .exAccent.opacity(0.75)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(level.subtitle).font(.caption).foregroundColor(.primary)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Text("全\(level.rounds.count)回・\(level.rounds.reduce(0) { $0 + $1.questionCount })問・1回\(level.rounds.first?.totalPoints ?? 0)点満点")
                    .font(.caption2).foregroundColor(.secondary)
                if store.isPurchased(level) {
                    Label("購入済み・全回が解けます", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.semibold)).foregroundColor(.green)
                } else {
                    Text("第1回は無料" + (store.priceText(level).map { "・全回 \($0)" } ?? ""))
                        .font(.caption2.weight(.semibold)).foregroundColor(.exAccent)
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

// MARK: - 級のホーム（回の一覧・購入）

struct LevelHomeView: View {
    let level: ExamLevel
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 8) {
                    FlagBar(label: level.level).frame(height: 52)
                    Text(level.subtitle)
                        .font(.caption).foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("模擬試験 全\(level.rounds.count)回　筆記試験対策（\(level.rounds.first?.totalPoints ?? 0)点満点）")
                        .font(.caption2).foregroundColor(.secondary)
                }
                .padding(.top, 8)
                if !store.isPurchased(level) { PurchaseCard(level: level) }
                ForEach(level.rounds) { round in
                    if store.isUnlocked(level, round: round) {
                        NavigationLink(value: RoundRef(level: level, round: round)) {
                            RoundCard(round: round, level: level, locked: false)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button { Task { await store.buy(level) } } label: {
                            RoundCard(round: round, level: level, locked: true)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.busy != nil)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(level.level)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RoundCard: View {
    let round: ExamRound
    let level: ExamLevel
    var locked: Bool = false
    @ObservedObject private var store = RecordStore.shared

    var body: some View {
        HStack(spacing: 14) {
            Text("第\(round.round)回")
                .font(.headline.weight(.bold)).foregroundColor(.white)
                .frame(width: 72, height: 64)
                .background(LinearGradient(colors: locked ? [.gray, .gray.opacity(0.75)] : [.exAccent, .exAccent.opacity(0.75)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(round.title).font(.subheadline.weight(.semibold))
                Text("\(round.durationMin)分・\(round.questionCount)問・\(round.totalPoints)点満点")
                    .font(.caption2).foregroundColor(.secondary)
                if locked {
                    Text("購入すると解けます").font(.caption2.weight(.semibold)).foregroundColor(.secondary)
                } else if round.round <= FREE_ROUNDS && !StoreManager.shared.isPurchased(level) {
                    Text("無料でお試しいただけます").font(.caption2.weight(.semibold)).foregroundColor(.exAccent)
                }
                if !locked, let best = store.best(levelKey: level.key, round: round.round) {
                    Text("最高 \(best.total)/\(best.totalMax)点　\(best.reached ? "目安に到達" : "あと\(max(0, round.passing - best.total))点")")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(best.reached ? .green : .exRed)
                }
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right").font(.footnote.weight(.semibold))
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
