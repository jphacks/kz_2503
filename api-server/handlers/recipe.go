package handlers

import (
	"api-server/models"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// レシピ作成
func CreateRecipe(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	models.MockDB.Recipes[recipeID] = recipe
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "レシピを追加しました",
	})
}

// レシピ取得
func GetRecipe(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	models.MockDB.Mu.RLock()
	recipe, exists := models.MockDB.Recipes[recipeID]
	models.MockDB.Mu.RUnlock()

	if !exists {
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

// レシピ更新
func UpdateRecipe(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	var recipe models.Recipe
	if err := c.ShouldBindJSON(&recipe); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	recipe.RecipeID = recipeID

	models.MockDB.Mu.Lock()
	models.MockDB.Recipes[recipeID] = recipe
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "レシピを更新しました",
	})
}

// レシピ削除
func DeleteRecipe(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	models.MockDB.Mu.Lock()
	delete(models.MockDB.Recipes, recipeID)
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "レシピを削除しました",
	})
}

// 人気レシピ取得
func GetPopularRecipes(c *gin.Context) {
	models.MockDB.Mu.RLock()
	recipes := make([]models.RecipeSummary, 0)
	for _, recipe := range models.MockDB.Recipes {
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
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, models.RecipesResponse{
		Status:  200,
		Recipes: recipes,
	})
}

// 週間レシピ取得
func GetWeeklyRecipes(c *gin.Context) {
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

// ユーザーのレシピ取得
func GetUserRecipes(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	recipes := make([]models.RecipeSummary, 0)
	for _, recipe := range models.MockDB.Recipes {
		if recipe.UserID == userID {
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

// お気に入りレシピ取得
func GetFavoriteRecipes(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	favoriteRecipeIDs, exists := models.MockDB.FavoriteRecipes[userID]
	if !exists {
		models.MockDB.Mu.RUnlock()
		c.JSON(http.StatusOK, models.RecipesResponse{
			Status:  200,
			Recipes: []models.RecipeSummary{},
		})
		return
	}

	recipes := make([]models.RecipeSummary, 0)
	for _, recipeID := range favoriteRecipeIDs {
		if recipe, exists := models.MockDB.Recipes[recipeID]; exists {
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

// お気に入りレシピ追加
func AddFavoriteRecipe(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	// 既にお気に入りに追加されていないかチェック
	favorites := models.MockDB.FavoriteRecipes[userID]
	for _, id := range favorites {
		if id == request.RecipeID {
			models.MockDB.Mu.Unlock()
			c.JSON(http.StatusOK, models.Response{
				Status:  200,
				Message: "お気に入りに追加しました",
			})
			return
		}
	}

	// お気に入りに追加
	models.MockDB.FavoriteRecipes[userID] = append(favorites, request.RecipeID)
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "お気に入りに追加しました",
	})
}

// お気に入りレシピ削除
func RemoveFavoriteRecipe(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	favorites := models.MockDB.FavoriteRecipes[userID]
	for i, id := range favorites {
		if id == request.RecipeID {
			// スライスから削除
			models.MockDB.FavoriteRecipes[userID] = append(favorites[:i], favorites[i+1:]...)
			break
		}
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "お気に入りから削除しました",
	})
}
