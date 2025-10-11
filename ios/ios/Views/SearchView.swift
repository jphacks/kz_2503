// Views/SearchView.swift
import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー＋検索バー（あなたの既存そのままでOK）
            SearchHeader(
                text: $vm.query,                      // ← ここは your SearchHeader に合わせて
                onSubmit: { vm.submitSearch(); focused = false },
                onClear: { vm.clearQuery() }
            )
            .focused($focused)

            // 結果
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let msg = vm.errorMessage {
                        Text(msg)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                    }

                    if vm.titles.isEmpty, vm.errorMessage == nil {
                        Text("レシピが見つかりませんでした。")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                    } else {
                        ForEach(vm.titles, id: \.self) { title in
                            // 最小：タイトルだけ行表示（見た目はお好みで）
                            Text(title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.secondary.opacity(0.08))
                                )
                                .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
