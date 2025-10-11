package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// 検索履歴取得
func GetSearchHistory(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	searchWords, exists := models.MockDB.SearchHistory[userID]
	if !exists {
		models.MockDB.Mu.RUnlock()
		c.JSON(http.StatusOK, gin.H{
			"status": 200,
			"word":   []gin.H{},
		})
		return
	}

	words := make([]gin.H, len(searchWords))
	for i, word := range searchWords {
		words[i] = gin.H{"value": word}
	}
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"word":   words,
	})
}

// ワード検索
func SearchByWord(c *gin.Context) {
	word := c.Param("word")

	models.MockDB.Mu.RLock()
	recipes := make([]models.RecipeSummary, 0)
	for _, recipe := range models.MockDB.Recipes {
		// タイトルに検索ワードが含まれているかチェック（簡易実装）
		if contains(recipe.Title, word) {
			// ユーザー名を取得
			user, exists := models.MockDB.Users[recipe.UserID]
			chef := "Unknown"
			if exists {
				chef = user.Username
			}

			recipes = append(recipes, models.RecipeSummary{
				RecipeID:   recipe.RecipeID,
				Title:      recipe.Title,
				Chef:       chef,
				PictureURL: recipe.PictureURL,
			})
		}
	}
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, models.RecipesResponse{
		Status:  200,
		Recipes: recipes,
	})
}

// カテゴリ検索
func SearchByCategory(c *gin.Context) {
	categoryID := c.Param("category_id")

	models.MockDB.Mu.RLock()
	recipes := make([]models.RecipeSummary, 0)
	for _, recipe := range models.MockDB.Recipes {
		// カテゴリIDが一致するかチェック
		if recipe.CategoryID == categoryID {
			// ユーザー名を取得
			user, exists := models.MockDB.Users[recipe.UserID]
			chef := "Unknown"
			if exists {
				chef = user.Username
			}

			recipes = append(recipes, models.RecipeSummary{
				RecipeID:   recipe.RecipeID,
				Title:      recipe.Title,
				Chef:       chef,
				PictureURL: recipe.PictureURL,
			})
		}
	}
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, models.RecipesResponse{
		Status:  200,
		Recipes: recipes,
	})
}

// 文字列包含チェック（簡易実装）
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr ||
		(len(s) > len(substr) &&
			(s[:len(substr)] == substr ||
				s[len(s)-len(substr):] == substr ||
				containsHelper(s, substr))))
}

func containsHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
