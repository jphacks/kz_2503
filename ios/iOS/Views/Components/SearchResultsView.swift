//
//  SearchResultsView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct SearchResultsView: View {
    let recipes: [SearchRecipe]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(recipes, id: \.recipeId) { recipe in
                    RecipeCardView(
                        title: recipe.title,
                        ingredients: [], // APIレスポンスに材料情報がないため空配列
                        chefName: recipe.chef,
                        imageUrl: recipe.pictureUrl
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

#Preview {
    SearchResultsView(recipes: [
        SearchRecipe(
            recipeId: "1",
            title: "カレーライス",
            chef: "kota",
            pictureUrl: "https://i.imgur.com/ScEqnCM.png"
        ),
        SearchRecipe(
            recipeId: "2",
            title: "ハンバーグ",
            chef: "taro",
            pictureUrl: nil
        )
    ])
}

