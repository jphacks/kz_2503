package interfaces

import "api-server/models"

// リポジトリインターフェース
type Repository interface {
	// ユーザー関連
	CreateUser(user models.User) (*models.User, error)
	GetUser(userID string) (*models.User, error)
	GetUserByEmail(email string) (*models.User, error)
	UpdateUser(userID string, updates map[string]interface{}) error
	DeleteUser(userID string) error
	LoginUser(userID, passwordHash string) (*models.User, error)

	// レシピ関連
	CreateRecipe(recipe models.Recipe) (*models.Recipe, error)
	GetRecipe(recipeID string) (*models.Recipe, error)
	UpdateRecipe(recipeID string, updates map[string]interface{}) error
	DeleteRecipe(recipeID string) error
	GetPopularRecipes() ([]models.Recipe, error)
	GetWeeklyRecipes(date string) ([]models.Recipe, error)
	GetUserRecipes(userID string) ([]models.Recipe, error)
	GetFavoriteRecipes(userID string) ([]models.Recipe, error)
	AddFavoriteRecipe(userID, recipeID string) error
	RemoveFavoriteRecipe(userID, recipeID string) error

	// カテゴリ関連
	GetCategories() ([]models.Category, error)

	// コメント関連
	CreateComment(comment models.Comment) (*models.Comment, error)
	UpdateComment(commentID string, updates map[string]interface{}) error
	DeleteComment(commentID string) error

	// フォロー関連
	FollowUser(userID, followerID string) error
	UnfollowUser(userID, followerID string) error
	GetFollowers(userID string) ([]string, error)

	// ブロック関連
	BlockUser(userID, blockerID string) error
	UnblockUser(userID, blockerID string) error
	GetBlocks(userID string) ([]string, error)

	// 通知関連
	GetNotices(userID string) ([]models.Notice, error)
	UpdateNoticeStatus(userID string, noticeID string) error

	// 設定関連
	UpdateWinkSetting(userID string, isWink bool) error
	UpdateAISetting(userID string, isAI bool) error
	UpdateLocationSetting(userID string, location string) error

	// 検索関連
	GetSearchHistory(userID string) ([]string, error)
	SearchByWord(word string) ([]models.RecipeSummary, error)
	SearchByCategory(categoryID string) ([]models.Recipe, error)
}
