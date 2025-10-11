package handlers

import (
	"api-server/interfaces"
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// グローバルなリポジトリインスタンス
var recipeRepo interfaces.Repository

// レシピハンドラーを初期化
func InitRecipeHandler(repo interfaces.Repository) {
	recipeRepo = repo
}

// レシピ作成
func CreateRecipe(c *gin.Context) {
	var request models.Recipe
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	recipe, err := recipeRepo.CreateRecipe(request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "レシピ作成に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"recipe": recipe,
	})
}

// レシピ取得
func GetRecipe(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	recipe, err := recipeRepo.GetRecipe(recipeID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "レシピが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"recipe": recipe,
	})
}

// レシピ更新
func UpdateRecipe(c *gin.Context) {
	recipeID := c.Param("recipe_id")
	var request struct {
		Title        string `json:"title"`
		Point        string `json:"point"`
		PictureURL   string `json:"picture_url"`
		ServingCount int    `json:"serving_count"`
		Status       string `json:"status"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	updates := map[string]interface{}{
		"title":         request.Title,
		"point":         request.Point,
		"picture_url":   request.PictureURL,
		"serving_count": request.ServingCount,
		"status":        request.Status,
	}

	err := recipeRepo.UpdateRecipe(recipeID, updates)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "レシピが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "レシピを更新しました",
	})
}

// レシピ削除
func DeleteRecipe(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	err := recipeRepo.DeleteRecipe(recipeID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "レシピが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "レシピを削除しました",
	})
}

// 人気レシピ取得
func GetPopularRecipes(c *gin.Context) {
	recipes, err := recipeRepo.GetPopularRecipes()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "レシピ取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"recipes": recipes,
	})
}

// 週間レシピ取得
func GetWeeklyRecipes(c *gin.Context) {
	date := c.Param("date")

	recipes, err := recipeRepo.GetWeeklyRecipes(date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "レシピ取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"recipes": recipes,
	})
}

// ユーザーレシピ取得
func GetUserRecipes(c *gin.Context) {
	userID := c.Param("user_id")

	recipes, err := recipeRepo.GetUserRecipes(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "レシピ取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"recipes": recipes,
	})
}

// お気に入りレシピ取得
func GetFavoriteRecipes(c *gin.Context) {
	userID := c.Param("user_id")

	recipes, err := recipeRepo.GetFavoriteRecipes(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "レシピ取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"recipes": recipes,
	})
}

// お気に入りレシピ追加
func AddFavoriteRecipe(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		RecipeID string `json:"recipe_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := recipeRepo.AddFavoriteRecipe(userID, request.RecipeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "お気に入り追加に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "お気に入りに追加しました",
	})
}

// お気に入りレシピ削除
func RemoveFavoriteRecipe(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		RecipeID string `json:"recipe_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := recipeRepo.RemoveFavoriteRecipe(userID, request.RecipeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "お気に入り削除に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "お気に入りから削除しました",
	})
}
