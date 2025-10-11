package main

import (
	"api-server/config"
	"api-server/handlers"
	"api-server/interfaces"
	"api-server/models"
	"api-server/repositories"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// 環境変数を読み込み
	if err := godotenv.Load("config.env"); err != nil {
		log.Println("No config.env file found, using system environment variables")
	}

	// リポジトリの選択（環境変数で切り替え）
	var repo interfaces.Repository
	repositoryType := os.Getenv("REPOSITORY_TYPE")
	useSupabase := os.Getenv("USE_SUPABASE") == "true" || repositoryType == "supabase"

	if useSupabase {
		// Supabaseクライアントを初期化
		config.InitSupabase()
		repo = repositories.NewSupabaseRepository()
		log.Println("Using Supabase repository")
	} else {
		// モックデータを初期化
		models.InitMockData()
		repo = repositories.NewMockRepository()
		log.Println("Using Mock repository")
	}

	// ハンドラーを初期化
	handlers.InitUserHandler(repo)
	handlers.InitRecipeHandler(repo)
	handlers.InitCategoryHandler(repo)
	handlers.InitCommentHandler(repo)
	handlers.InitFollowHandler(repo)
	handlers.InitBlockHandler(repo)
	handlers.InitNoticeHandler(repo)
	handlers.InitSettingHandler(repo)
	handlers.InitSearchHandler(repo)

	// Ginルーターを設定
	r := gin.Default()

	// CORS設定
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(200)
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

	// カテゴリ関連のルート
	r.GET("/category", handlers.GetCategories)

	// コメント関連のルート
	comment := r.Group("/comment")
	{
		comment.POST("/:recipe_id", handlers.CreateComment)
		comment.PATCH("/:recipe_id", handlers.UpdateComment)
		comment.DELETE("/:recipe_id", handlers.DeleteComment)
	}

	// フォロー関連のルート
	follow := r.Group("/follow")
	{
		follow.POST("/:user_id", handlers.FollowUser)
		follow.DELETE("/:user_id", handlers.UnfollowUser)
		follow.GET("/:user_id", handlers.GetFollowers)
	}

	// ブロック関連のルート
	block := r.Group("/block")
	{
		block.POST("/:user_id", handlers.BlockUser)
		block.DELETE("/:user_id", handlers.UnblockUser)
		block.GET("/:user_id", handlers.GetBlocks)
	}

	// 通知関連のルート
	notice := r.Group("/notice")
	{
		notice.GET("/:user_id", handlers.GetNotices)
		notice.PATCH("/:user_id", handlers.UpdateNoticeStatus)
	}

	// 設定関連のルート
	settings := r.Group("/settings")
	{
		settings.PATCH("/wink/:user_id", handlers.UpdateWinkSetting)
		settings.PATCH("/ai/:user_id", handlers.UpdateAISetting)
		settings.PATCH("/location/:user_id", handlers.UpdateLocationSetting)
	}

	// 検索関連のルート
	search := r.Group("/search")
	{
		search.GET("/:user_id", handlers.GetSearchHistory)
		search.GET("/word/:word", handlers.SearchByWord)
		search.GET("/category/:category_id", handlers.SearchByCategory)
	}

	// サーバーを起動
	log.Println("Server starting on :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
