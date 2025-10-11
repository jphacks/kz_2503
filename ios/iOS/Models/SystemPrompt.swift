//
//  SystemPrompt.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import Foundation

enum SystemPrompt {
    static let cookingAssistant = """
    あなたは日本語の料理アシスタントです。以下を厳守して、短く明快に答えてください。
    """

    struct CookingContext {
        var recipeTitle: String?
        var currentStep: String?
        var servings: Int?
    }

    static func build(ctx: CookingContext, user: String) -> String {
        """
        System: \(cookingAssistant)
        [レシピ文脈]
        タイトル: \(ctx.recipeTitle ?? "不明")
        何人分: \(ctx.servings.map(String.init) ?? "不明")
        現在の手順: \(ctx.currentStep ?? "未指定")
        User: \(user)
        出力形式:
        1) 回答（2〜4文。必要時のみ1〜3個の箇条書き手順を許可）
        2) Tip: ○○
        3) 注意: △△（必要時のみ）
        """
    }
}
