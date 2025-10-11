//
//  SearchViewModel.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchHistory: [String] = []
    @Published var searchResults: [SearchRecipe] = []
    @Published var popularRecipes: [PopularRecipe] = []
    @Published var userInfoCache: [String: UserInfo] = [:]
    @Published var isLoading: Bool = false
    @Published var isLoadingPopularRecipes: Bool = false
    @Published var errorMessage: String?
    @Published var popularRecipesErrorMessage: String?
    @Published var showSearchResults: Bool = false
    
    private let searchHistoryRepository = SearchHistoryRepository()
    private let searchWordRepository = SearchWordRepository()
    private let popularRecipeRepository = PopularRecipeRepository()
    private let userRepository = UserRepository()
    
    init() {
        loadSearchHistory()
        loadPopularRecipes()
    }
    
    func loadSearchHistory() {
        Task {
            let result = await searchHistoryRepository.getSearchHistory()
            switch result {
            case .success(let words):
                searchHistory = words
            case .error(let message):
                print("Failed to load search history: \(message)")
            }
        }
    }
    
    func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        Task {
            await searchWord(query)
        }
    }
    
    func searchFromHistory(_ word: String) {
        searchText = word
        Task {
            await searchWord(word)
        }
    }
    
    private func searchWord(_ word: String) async {
        isLoading = true
        errorMessage = nil
        
        let result = await searchWordRepository.searchWord(word)
        
        isLoading = false
        
        switch result {
        case .success(let recipes):
            searchResults = recipes
            showSearchResults = true
            // 履歴に追加（重複を避ける）
            if !searchHistory.contains(word) {
                searchHistory.insert(word, at: 0)
                // 履歴は最大10件まで
                if searchHistory.count > 10 {
                    searchHistory = Array(searchHistory.prefix(10))
                }
            }
            
        case .error(let message):
            errorMessage = message
            searchResults = []
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        showSearchResults = false
        errorMessage = nil
    }
    
    func loadPopularRecipes() {
        isLoadingPopularRecipes = true
        popularRecipesErrorMessage = nil
        
        Task {
            let result = await popularRecipeRepository.getPopularRecipes()
            
            isLoadingPopularRecipes = false
            
            switch result {
            case .success(let recipes):
                popularRecipes = recipes
                print("✅ Loaded \(recipes.count) popular recipes")
                // 各レシピのユーザー情報を取得
                await loadUserInfoForRecipes(recipes)
            case .error(let message):
                print("❌ Failed to load popular recipes: \(message)")
                popularRecipesErrorMessage = message
                // エラーが発生してもUIを壊さないように、空の配列を設定
                popularRecipes = []
            }
        }
    }
    
    private func loadUserInfoForRecipes(_ recipes: [PopularRecipe]) async {
        for recipe in recipes {
            // 既にキャッシュされている場合はスキップ
            if userInfoCache[recipe.userId] != nil {
                continue
            }
            
            let result = await userRepository.getUserInfo(userId: recipe.userId)
            switch result {
            case .success(let userInfo):
                userInfoCache[recipe.userId] = userInfo
                print("✅ Loaded user info for: \(userInfo.username)")
            case .error(let message):
                print("❌ Failed to load user info for \(recipe.userId): \(message)")
                // エラーが発生してもUIを壊さないように、デフォルトのユーザー情報を設定
                let defaultUserInfo = UserInfo(
                    userId: recipe.userId,
                    username: "ユーザー",
                    mailadress: "",
                    profile: "",
                    icon: "",
                    isWink: false,
                    location: "",
                    isAi: false
                )
                userInfoCache[recipe.userId] = defaultUserInfo
            }
        }
    }
    
    func getUserInfo(for userId: String) -> UserInfo? {
        return userInfoCache[userId]
    }
}
