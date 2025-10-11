import SwiftUI

struct SearchHeader: View {
    @Binding var text: String
    @FocusState var focused: Bool
    var onSubmit: () -> Void
    var onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                HeaderAvatarButton { /* open profile */ }
                HeaderTitle("さがす")
                    .frame(maxWidth: .infinity, alignment: .leading)
                HeaderBellButton { /* open notifications */ }
            }

            // 検索バー
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                TextField("検索", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit { onSubmit(); focused = false }

                if !text.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("クリア")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .focused($focused)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
        .onTapGesture { focused = false }
    }
}
