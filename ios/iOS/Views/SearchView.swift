//
//  SearchView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                // プロフィール画像
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Spacer()
                
                Text("さがす")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // 通知ベル
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
                
                TextField("検索", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.performSearch()
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button("検索") {
                        viewModel.performSearch()
                    }
                    .foregroundColor(.blue)
                    .padding(.trailing, 12)
                }
            }
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // メインコンテンツ
            if viewModel.showSearchResults {
                // 検索結果
                SearchResultsView(recipes: viewModel.searchResults)
            } else {
                // 履歴と新着
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 検索履歴
                        if !viewModel.searchHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("検索履歴")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(viewModel.searchHistory, id: \.self) { word in
                                        Button(action: {
                                            viewModel.searchFromHistory(word)
                                        }) {
                                            Text(word)
                                                .font(.caption)
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(Color.gray.opacity(0.1))
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // 人気レシピ
                        VStack(alignment: .leading, spacing: 16) {
                            Text("人気レシピ")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            
                            if viewModel.isLoadingPopularRecipes {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            } else if let errorMessage = viewModel.popularRecipesErrorMessage {
                                VStack(spacing: 12) {
                                    Text("人気レシピの読み込みに失敗しました")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    Text(errorMessage)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                    Button("再試行") {
                                        viewModel.loadPopularRecipes()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                            } else if viewModel.popularRecipes.isEmpty {
                                Text("人気レシピが見つかりませんでした")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.popularRecipes, id: \.recipeId) { recipe in
                                        RecipeCardView(
                                            title: recipe.title,
                                            ingredients: recipe.recipeMaterial, // 実際の材料データを使用
                                            chefName: "ユーザー", // chef情報がないためデフォルト値
                                            imageUrl: recipe.pictureUrl.isEmpty ? nil : recipe.pictureUrl
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
            
            Spacer()
        }
        .background(Color.white)
        .overlay(
            // エラーメッセージ
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                        .padding(.horizontal, 20)
                }
            }
            .animation(.easeInOut, value: viewModel.errorMessage)
        )
        .overlay(
            // ローディング
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        )
        .overlay(
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // TODO: 新規レシピ作成
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        )
        .overlay(
            // ボトムナビゲーション
            VStack {
                Spacer()
                BottomNavigationView()
            }
        )
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}