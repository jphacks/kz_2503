import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ===== Header =====
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    HeaderAvatarButton { /* open profile */ }

                    HeaderTitle("さがす")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HeaderBellButton { /* open notifications */ }
                }

                // 検索バー（再利用しないので直書き）
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)

                    TextField("検索", text: $vm.query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.search)
                        .onSubmit { vm.submitSearch(); focused = false }

                    if !vm.query.isEmpty {
                        Button(action: { vm.clearQuery() }) {
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

            // ===== Body（必要になったら実装。今は空） =====
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// Preview
#Preview("SearchView") { SearchView() }
