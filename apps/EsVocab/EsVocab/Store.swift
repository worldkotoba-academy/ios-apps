import Foundation
import SwiftUI

// MARK: - 学習状態の保存（UserDefaults・端末内のみ）

final class Store: ObservableObject {
    static let shared = Store()

    @Published private(set) var known: Set<String> = []      // 覚えた
    @Published private(set) var weak: Set<String> = []       // 苦手
    @Published private(set) var favorite: Set<String> = []   // お気に入り

    private let kKnown = STORE_PREFIX + ".known"
    private let kWeak = STORE_PREFIX + ".weak"
    private let kFav = STORE_PREFIX + ".favorite"

    private init() {
        let d = UserDefaults.standard
        known = Set(d.stringArray(forKey: kKnown) ?? [])
        weak = Set(d.stringArray(forKey: kWeak) ?? [])
        favorite = Set(d.stringArray(forKey: kFav) ?? [])
    }

    func isKnown(_ id: String) -> Bool { known.contains(id) }
    func isWeak(_ id: String) -> Bool { weak.contains(id) }
    func isFavorite(_ id: String) -> Bool { favorite.contains(id) }

    func toggleKnown(_ id: String) {
        if known.contains(id) { known.remove(id) } else { known.insert(id); weak.remove(id) }
        save()
    }
    func setKnown(_ id: String, _ v: Bool) {
        if v { known.insert(id); weak.remove(id) } else { known.remove(id) }
        save()
    }
    func toggleWeak(_ id: String) {
        if weak.contains(id) { weak.remove(id) } else { weak.insert(id); known.remove(id) }
        save()
    }
    func markWeak(_ id: String) {
        weak.insert(id); known.remove(id); save()
    }
    func toggleFavorite(_ id: String) {
        if favorite.contains(id) { favorite.remove(id) } else { favorite.insert(id) }
        save()
    }

    /// 級・パート単位の習得数
    func knownCount(_ words: [VocabWord]) -> Int { words.reduce(0) { $0 + (known.contains($1.id) ? 1 : 0) } }

    func resetLevel(_ level: VocabLevel) {
        for w in level.words { known.remove(w.id); weak.remove(w.id) }
        save()
    }

    private func save() {
        let d = UserDefaults.standard
        d.set(Array(known), forKey: kKnown)
        d.set(Array(weak), forKey: kWeak)
        d.set(Array(favorite), forKey: kFav)
    }
}
