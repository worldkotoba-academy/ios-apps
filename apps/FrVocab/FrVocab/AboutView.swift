import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(ABOUT_SECTIONS.enumerated()), id: \.offset) { _, s in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(s.0).font(.subheadline.weight(.bold)).foregroundColor(.vcAccent)
                        Text(s.1).font(.footnote).foregroundColor(.primary.opacity(0.85))
                            .lineSpacing(2).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text("© 2026 Miyu Okazaki").font(.caption).foregroundColor(.secondary).padding(.top, 4)
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("このアプリについて")
        .navigationBarTitleDisplayMode(.inline)
    }
}
