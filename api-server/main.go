package main

import (
	"api-server/config"
	"api-server/handlers"
	"api-server/models"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// 環境変数を読み込み
	if err := godotenv.Load("config.env"); err != nil {
		log.Println("No config.env file found, using system environment variables")
	}

	// Supabaseクライアントを初期化
	config.InitSupabase()
	models.InitDatabase()

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

	// レシピ関連のルート（Supabase版）
	recipe := r.Group("/recipe")
	{
		recipe.POST("", handlers.CreateRecipeDB)
		recipe.GET("/:recipe_id", handlers.GetRecipeDB)
		recipe.PATCH("/:recipe_id", handlers.UpdateRecipeDB)
		recipe.DELETE("/:recipe_id", handlers.DeleteRecipeDB)
		recipe.GET("/popular", handlers.GetPopularRecipesDB)
		recipe.GET("/weekly/:date", handlers.GetWeeklyRecipesDB)
		recipe.GET("/user/:user_id", handlers.GetUserRecipesDB)
		recipe.GET("/favorite/:user_id", handlers.GetFavoriteRecipesDB)
		recipe.POST("/favorite/:user_id", handlers.AddFavoriteRecipeDB)
		recipe.DELETE("/favorite/:user_id", handlers.RemoveFavoriteRecipeDB)
	}

	// ユーザー関連のルート（Supabase版）
	user := r.Group("/user")
	{
		user.POST("", handlers.CreateUserDB)
		user.GET("/:user_id", handlers.GetUserDB)
		user.DELETE("/:user_id", handlers.DeleteUserDB)
		user.POST("/login", handlers.LoginUserDB)
		user.PATCH("/profile/:user_id", handlers.UpdateUserProfileDB)
		user.PATCH("/password/:user_id", handlers.UpdateUserPasswordDB)
		user.PATCH("/icon/:user_id", handlers.UpdateUserIconDB)
	}

	// カテゴリ関連のルート（Supabase版）
	r.GET("/category", handlers.GetCategoriesDB)

	// コメント関連のルート（Supabase版）
	comment := r.Group("/comment")
	{
		comment.POST("/:recipe_id", handlers.CreateCommentDB)
		comment.PATCH("/:recipe_id", handlers.UpdateCommentDB)
		comment.DELETE("/:recipe_id", handlers.DeleteCommentDB)
	}

	// フォロー関連のルート（Supabase版）
	follow := r.Group("/follow")
	{
		follow.POST("/:user_id", handlers.FollowUserDB)
		follow.DELETE("/:user_id", handlers.UnfollowUserDB)
		follow.GET("/:user_id", handlers.GetFollowersDB)
	}

	// ブロック関連のルート（Supabase版）
	block := r.Group("/block")
	{
		block.POST("/:user_id", handlers.BlockUserDB)
		block.DELETE("/:user_id", handlers.UnblockUserDB)
		block.GET("/:user_id", handlers.GetBlocksDB)
	}

	// 通知関連のルート（Supabase版）
	notice := r.Group("/notice")
	{
		notice.GET("/:user_id", handlers.GetNoticesDB)
		notice.PATCH("/:user_id", handlers.UpdateNoticeStatusDB)
	}

	// 設定関連のルート（Supabase版）
	settings := r.Group("/settings")
	{
		settings.PATCH("/wink/:user_id", handlers.UpdateWinkSettingDB)
		settings.PATCH("/ai/:user_id", handlers.UpdateAISettingDB)
		settings.PATCH("/location/:user_id", handlers.UpdateLocationSettingDB)
	}

	// 検索関連のルート（Supabase版）
	search := r.Group("/search")
	{
		search.GET("/:user_id", handlers.GetSearchHistoryDB)
		search.GET("/word/:word", handlers.SearchByWordDB)
		search.GET("/category/:category_id", handlers.SearchByCategoryDB)
	}

	// サーバーを起動
	log.Println("Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
