package handlers

import (
	"api-server/models"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// レシピ作成（Supabase版）
func CreateRecipeDB(c *gin.Context) {
	var recipe models.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	// レシピIDを生成（簡易的な実装）
	recipeID := fmt.Sprintf("%d", time.Now().Unix())
	recipe.RecipeID = recipeID

	result, err := models.DB.CreateRecipe(recipe)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "レシピを追加しました",
	})
}

// レシピ取得（Supabase版）
func GetRecipeDB(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	recipe, err := models.DB.GetRecipe(recipeID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	// レスポンス用の構造体に変換
	response := models.RecipeResponse{
		Status:         200,
		UserID:         recipe.UserID,
		CategoryID:     recipe.CategoryID,
		StatusField:    recipe.Status,
		Title:          recipe.Title,
		PictureURL:     recipe.PictureURL,
		Point:          recipe.Point,
		ServingCount:   recipe.ServingCount,
		RecipeMaterial: recipe.RecipeMaterial,
		RecipeContent:  recipe.RecipeContent,
	}

	c.JSON(http.StatusOK, response)
}

// レシピ更新（Supabase版）
func UpdateRecipeDB(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	var recipe models.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	updates := map[string]interface{}{
		"user_id":       recipe.UserID,
		"category_id":   recipe.CategoryID,
		"status":        recipe.Status,
		"title":         recipe.Title,
		"picture_url":   recipe.PictureURL,
		"point":         recipe.Point,
		"serving_count": recipe.ServingCount,
	}

	err := models.DB.UpdateRecipe(recipeID, updates)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "レシピを更新しました",
	})
}

// レシピ削除（Supabase版）
func DeleteRecipeDB(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	err := models.DB.DeleteRecipe(recipeID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "レシピを削除しました",
	})
}

// 人気レシピ取得（Supabase版）
func GetPopularRecipesDB(c *gin.Context) {
	recipes, err := models.DB.GetPopularRecipes()
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.RecipesResponse{
		Status:  200,
		Recipes: recipes,
	})
}

// 週間レシピ取得（Supabase版）
func GetWeeklyRecipesDB(c *gin.Context) {
	date := c.Param("date")
	_ = date // 日付パラメータは使用しない（モック実装）

	// モックデータで週間レシピを返す
	weeklyRecipe := models.WeeklyRecipe{
		RecipeID:   "123",
		Title:      "カレー",
		Chef:       "kota",
		PictureURL: "https://i.imgur.com/ScEqnCM.png",
	}

	response := models.WeeklyRecipesResponse{
		Status:    200,
		Sunday:    &weeklyRecipe,
		Monday:    &weeklyRecipe,
		Tuesday:   &weeklyRecipe,
		Wednesday: &weeklyRecipe,
		Thursday:  &weeklyRecipe,
		Friday:    &weeklyRecipe,
		Saturday:  &weeklyRecipe,
	}

	c.JSON(http.StatusOK, response)
}

// ユーザーのレシピ取得（Supabase版）
func GetUserRecipesDB(c *gin.Context) {
	userID := c.Param("user_id")

	recipes, err := models.DB.GetUserRecipes(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.RecipesResponse{
		Status:  200,
		Recipes: recipes,
	})
}

// お気に入りレシピ取得（Supabase版）
func GetFavoriteRecipesDB(c *gin.Context) {
	userID := c.Param("user_id")

	recipes, err := models.DB.GetFavoriteRecipes(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.RecipesResponse{
		Status:  200,
		Recipes: recipes,
	})
}

// お気に入りレシピ追加（Supabase版）
func AddFavoriteRecipeDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		RecipeID string `json:"recipe_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.AddFavoriteRecipe(userID, request.RecipeID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "お気に入りに追加しました",
	})
}

// お気に入りレシピ削除（Supabase版）
func RemoveFavoriteRecipeDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		RecipeID string `json:"recipe_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.RemoveFavoriteRecipe(userID, request.RecipeID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "お気に入りから削除しました",
	})
}
