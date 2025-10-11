import SwiftUI

struct RecipeRow: View {
    let title: String
    let materials: [String]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                if !materials.isEmpty {
                    Text(materials.prefix(2).joined(separator: ", ") +
                         (materials.count > 2 ? ", …" : ""))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.08)))
        .padding(.horizontal, 20)
    }
}
