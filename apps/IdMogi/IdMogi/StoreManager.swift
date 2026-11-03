import StoreKit
import SwiftUI

// MARK: - 級ごとのアプリ内課金（非消耗型・買い切り）
// 1つのアプリに全級を入れ、各級の第1回は無料、第2回以降は級ごとの購入で解ける（App Store ガイドライン 4.3(a) の推奨どおり）。
// 購入の確認は StoreKit 2 の Transaction（端末内で検証済みのもの）だけで行う。サーバー・アカウント登録は使わない。

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    /// 級の key → 商品
    @Published private(set) var products: [String: Product] = [:]
    /// 購入済みの級の key
    @Published private(set) var purchased: Set<String> = []
    /// 処理中の級の key（"restore"＝復元中）
    @Published var busy: String? = nil
    /// 利用者に知らせる一言（アラートで出す）
    @Published var message: String? = nil

    private var updates: Task<Void, Never>? = nil
    #if DEBUG
    /// ストア用スクリーンショットの撮影中だけ使う（製品版には入らない）
    var screenshotUnlocked: Set<String>? = nil
    #endif

    private init() {
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await refresh(); await loadProducts() }
    }

    // MARK: 判定

    func isPurchased(_ level: ExamLevel) -> Bool {
        #if DEBUG
        if let s = screenshotUnlocked { return s.contains(level.key) }
        #endif
        return purchased.contains(level.key)
    }

    /// 第 FREE_ROUNDS 回までは無料
    func isUnlocked(_ level: ExamLevel, round: ExamRound) -> Bool {
        round.round <= FREE_ROUNDS || isPurchased(level)
    }

    func priceText(_ level: ExamLevel) -> String? {
        if let p = products[level.key] { return p.displayPrice }
        #if DEBUG
        if screenshotUnlocked != nil { return PRICE_LABELS[level.key] }
        #endif
        return nil
    }

    // MARK: 読み込み

    func loadProducts() async {
        do {
            let ps = try await Product.products(for: Array(PRODUCT_IDS.values))
            var map: [String: Product] = [:]
            for p in ps {
                if let k = key(for: p.id) { map[k] = p }
            }
            products = map
        } catch {
            // 通信できないときは価格を出さないだけ（無料の回はそのまま使える）
        }
    }

    func refresh() async {
        var s: Set<String> = []
        for await r in StoreKit.Transaction.currentEntitlements {
            if case .verified(let t) = r, t.revocationDate == nil, let k = key(for: t.productID) {
                s.insert(k)
            }
        }
        purchased = s
    }

    private func key(for productID: String) -> String? {
        PRODUCT_IDS.first { $0.value == productID }?.key
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let t) = result else { return }
        if let k = key(for: t.productID) {
            if t.revocationDate == nil { purchased.insert(k) } else { purchased.remove(k) }
        }
        await t.finish()
    }

    // MARK: 購入・復元

    func buy(_ level: ExamLevel) async {
        if products[level.key] == nil { await loadProducts() }
        guard let p = products[level.key] else {
            message = "商品情報を読み込めませんでした。通信できる状態で、もう一度お試しください。"
            return
        }
        busy = level.key
        defer { busy = nil }
        do {
            switch try await p.purchase() {
            case .success(let v):
                await handle(v)
                if isPurchased(level) { message = "\(level.level)を購入しました。すべての回が解けるようになりました。" }
            case .pending:
                message = "購入の承認待ちです。承認されると自動で解けるようになります。"
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "購入を完了できませんでした。時間をおいて、もう一度お試しください。"
        }
    }

    func restore() async {
        busy = "restore"
        defer { busy = nil }
        do { try await AppStore.sync() } catch { }
        await refresh()
        message = purchased.isEmpty ? "復元できる購入はありませんでした。" : "購入を復元しました（\(purchasedNames)）。"
    }

    private var purchasedNames: String {
        ExamData.levels.filter { purchased.contains($0.key) }.map(\.level).joined(separator: "・")
    }
}

// MARK: - 購入の案内（級のホームと回のホームに出す）

struct PurchaseCard: View {
    let level: ExamLevel
    @ObservedObject private var store = StoreManager.shared

    private var paidRange: String {
        let n = level.rounds.count
        return FREE_ROUNDS + 1 == n ? "第\(n)回" : "第\(FREE_ROUNDS + 1)〜\(n)回"
    }

    private var paidQuestions: Int {
        level.rounds.filter { $0.round > FREE_ROUNDS }.reduce(0) { $0 + $1.questionCount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("\(level.level)の\(paidRange)は購入すると解けます", systemImage: "lock.fill")
                .font(.subheadline.weight(.bold)).foregroundColor(.exAccent)
            Text("第1回は無料でお試しいただけます。購入すると\(paidRange)（\(paidQuestions)問）が解けるようになります。"
                 + "級ごとの買い切りで、追加の料金はかかりません。")
                .font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await store.buy(level) }
            } label: {
                HStack {
                    Spacer()
                    if store.busy == level.key {
                        ProgressView().tint(.white)
                    } else {
                        Text(store.priceText(level).map { "\(level.level)を購入（\($0)）" } ?? "価格を読み込み中…")
                            .font(.subheadline.weight(.bold))
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(Color.exAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(store.busy != nil || store.priceText(level) == nil)
            RestoreButton()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct RestoreButton: View {
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        Button {
            Task { await store.restore() }
        } label: {
            HStack(spacing: 6) {
                if store.busy == "restore" { ProgressView() }
                Text("購入を復元").font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.exAccent)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(store.busy != nil)
    }
}

/// 購入・復元の結果を知らせるアラート
struct StoreMessageModifier: ViewModifier {
    @ObservedObject private var store = StoreManager.shared

    func body(content: Content) -> some View {
        content.alert(store.message ?? "", isPresented: Binding(
            get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
            Button("OK", role: .cancel) { store.message = nil }
        }
    }
}

extension View {
    func storeMessages() -> some View { modifier(StoreMessageModifier()) }
}
