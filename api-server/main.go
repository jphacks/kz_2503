package main

import (
	"api-server/handlers"
	"api-server/models"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	// モックデータを初期化
	models.InitMockData()

	// Ginルーターを設定
	r := gin.Default()

	// CORS設定
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// レシピ関連のルート
	recipe := r.Group("/recipe")
	{
		recipe.POST("", handlers.CreateRecipe)
		recipe.GET("/:recipe_id", handlers.GetRecipe)
		recipe.PATCH("/:recipe_id", handlers.UpdateRecipe)
		recipe.DELETE("/:recipe_id", handlers.DeleteRecipe)
		recipe.GET("/popular", handlers.GetPopularRecipes)
		recipe.GET("/weekly/:date", handlers.GetWeeklyRecipes)
		recipe.GET("/user/:user_id", handlers.GetUserRecipes)
		recipe.GET("/favorite/:user_id", handlers.GetFavoriteRecipes)
		recipe.POST("/favorite/:user_id", handlers.AddFavoriteRecipe)
		recipe.DELETE("/favorite/:user_id", handlers.RemoveFavoriteRecipe)
	}

	// ユーザー関連のルート
	user := r.Group("/user")
	{
		user.POST("", handlers.CreateUser)
		user.GET("/:user_id", handlers.GetUser)
		user.DELETE("/:user_id", handlers.DeleteUser)
		user.POST("/login", handlers.LoginUser)
		user.PATCH("/profile/:user_id", handlers.UpdateUserProfile)
		user.PATCH("/password/:user_id", handlers.UpdateUserPassword)
		user.PATCH("/icon/:user_id", handlers.UpdateUserIcon)
	}

	// サーバーを起動
	log.Println("Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
