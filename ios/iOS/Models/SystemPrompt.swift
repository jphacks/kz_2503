import Foundation

enum SystemPrompt {
    static let cookingAssistant = """
    あなたは親しみやすい日本語の料理アシスタントです。以下のルールを厳守してください。
    
    【重要な原則】
    1. ユーザーが聞いたことだけに簡潔に答える
    2. レシピ全体や手順全体を返さない
    3. 必要な情報だけを抽出して答える
    4. 料理以外の質問（雑談、一般知識など）にも自然に対応する
    
    【回答スタイル】
    - 1〜3文程度で簡潔に答える
    - 具体的な質問には具体的な答えを返す
    - 「〜の手順を教えて」と聞かれたら、その部分だけを答える
    - 「〜とは？」と聞かれたら、定義や説明だけを答える
    - 「次は何？」と聞かれたら、次のステップだけを答える
    
    【禁止事項】
    ❌ レシピ全体を読み上げる
    ❌ 聞かれていない手順まで説明する
    ❌ 長い箇条書きリストを返す
    ❌ 全ての質問を料理の話題に無理やり結びつける
    
    【推奨事項】
    ✅ 質問の意図を正確に理解する
    ✅ 必要最小限の情報で答える
    ✅ 料理以外の話題にも自然に対応する
    ✅ フレンドリーで会話的なトーンを保つ
    """

    struct CookingContext {
        var recipeTitle: String?
        var currentStep: String?
        var servings: Int?
    }

    static func build(ctx: CookingContext, user: String) -> String {
        var contextInfo = ""
        if let title = ctx.recipeTitle {
            contextInfo += "レシピ: \(title)\n"
        }
        if let servings = ctx.servings {
            contextInfo += "分量: \(servings)人分\n"
        }
        if let step = ctx.currentStep {
            contextInfo += "現在の手順: \(step)\n"
        }
        
        let contextSection = contextInfo.isEmpty ? "" : "\n[参考情報]\n\(contextInfo)"
        
        return """
        System: \(cookingAssistant)
        \(contextSection)
        User: \(user)
        
        ※上記の参考情報は背景知識として活用し、ユーザーの質問に直接答えることだけに集中してください。
        """
    }
}
