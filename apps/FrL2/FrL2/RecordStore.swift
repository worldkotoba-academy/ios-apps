import Foundation

// MARK: - 受験結果の保存（UserDefaults・端末内のみ）

struct SubjectScore: Codable, Identifiable {
    let title: String
    let score: Int
    let max: Int
    var id: String { title }
    var ratio: Double { max > 0 ? Double(score) / Double(max) : 0 }
}

struct ExamRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let levelKey: String
    let round: Int
    let subjects: [SubjectScore]
    let passing: Int?

    var total: Int { subjects.reduce(0) { $0 + $1.score } }
    var totalMax: Int { subjects.reduce(0) { $0 + $1.max } }
    var reached: Bool { total >= (passing ?? Int(ceil(Double(totalMax) * 0.6))) }
}

final class RecordStore: ObservableObject {
    static let shared = RecordStore()
    private static let key = "futsukenRecords.v1"

    @Published private(set) var records: [ExamRecord] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([ExamRecord].self, from: data) {
            records = decoded
        }
    }

    func add(_ record: ExamRecord) { records.append(record); save() }

    func records(levelKey: String, round: Int) -> [ExamRecord] {
        records.filter { $0.levelKey == levelKey && $0.round == round }.sorted { $0.date > $1.date }
    }

    func best(levelKey: String, round: Int) -> ExamRecord? {
        records(levelKey: levelKey, round: round).max { $0.total < $1.total }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
