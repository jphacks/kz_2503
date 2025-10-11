package handlers

import (
	"api-server/interfaces"
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// グローバルなリポジトリインスタンス
var categoryRepo interfaces.Repository
var commentRepo interfaces.Repository
var followRepo interfaces.Repository
var blockRepo interfaces.Repository
var noticeRepo interfaces.Repository
var settingRepo interfaces.Repository
var searchRepo interfaces.Repository

// カテゴリハンドラーを初期化
func InitCategoryHandler(repo interfaces.Repository) {
	categoryRepo = repo
}

// コメントハンドラーを初期化
func InitCommentHandler(repo interfaces.Repository) {
	commentRepo = repo
}

// フォローハンドラーを初期化
func InitFollowHandler(repo interfaces.Repository) {
	followRepo = repo
}

// ブロックハンドラーを初期化
func InitBlockHandler(repo interfaces.Repository) {
	blockRepo = repo
}

// 通知ハンドラーを初期化
func InitNoticeHandler(repo interfaces.Repository) {
	noticeRepo = repo
}

// 設定ハンドラーを初期化
func InitSettingHandler(repo interfaces.Repository) {
	settingRepo = repo
}

// 検索ハンドラーを初期化
func InitSearchHandler(repo interfaces.Repository) {
	searchRepo = repo
}

// カテゴリ一覧取得
func GetCategories(c *gin.Context) {
	categories, err := categoryRepo.GetCategories()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "カテゴリ取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":   200,
		"category": categories,
	})
}

// コメント作成
func CreateComment(c *gin.Context) {
	recipeID := c.Param("recipe_id")
	var request models.Comment
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	request.RecipeID = recipeID
	comment, err := commentRepo.CreateComment(request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "コメント作成に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "コメントしました",
		"comment": comment,
	})
}

// コメント更新
func UpdateComment(c *gin.Context) {
	commentID := c.Param("comment_id")
	var request struct {
		Content string `json:"content"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	updates := map[string]interface{}{
		"content": request.Content,
	}

	err := commentRepo.UpdateComment(commentID, updates)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "コメントが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "コメントを更新しました",
	})
}

// コメント削除
func DeleteComment(c *gin.Context) {
	commentID := c.Param("comment_id")

	err := commentRepo.DeleteComment(commentID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "コメントが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "コメントを削除しました",
	})
}

// フォロー
func FollowUser(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		FollowerID string `json:"follower_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := followRepo.FollowUser(userID, request.FollowerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "フォローに失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "フォローしました",
	})
}

// アンフォロー
func UnfollowUser(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		FollowerID string `json:"follower_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := followRepo.UnfollowUser(userID, request.FollowerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "アンフォローに失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "アンフォローしました",
	})
}

// フォロワー一覧取得
func GetFollowers(c *gin.Context) {
	userID := c.Param("user_id")

	followers, err := followRepo.GetFollowers(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "フォロワー取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":    200,
		"followers": followers,
	})
}

// ブロック
func BlockUser(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		BlockerID string `json:"blocker_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := blockRepo.BlockUser(userID, request.BlockerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "ブロックに失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "ブロックしました",
	})
}

// アンブロック
func UnblockUser(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		BlockerID string `json:"blocker_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := blockRepo.UnblockUser(userID, request.BlockerID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "アンブロックに失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "アンブロックしました",
	})
}

// ブロック一覧取得
func GetBlocks(c *gin.Context) {
	userID := c.Param("user_id")

	blocks, err := blockRepo.GetBlocks(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "ブロック一覧取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"blocks": blocks,
	})
}

// 通知一覧取得
func GetNotices(c *gin.Context) {
	userID := c.Param("user_id")

	notices, err := noticeRepo.GetNotices(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "通知取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"notices": notices,
	})
}

// 通知ステータス更新
func UpdateNoticeStatus(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		NoticeID string `json:"notice_id"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := noticeRepo.UpdateNoticeStatus(userID, request.NoticeID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "通知更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "通知を更新しました",
	})
}

// ウィンク設定更新
func UpdateWinkSetting(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		IsWink bool `json:"is_wink"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := settingRepo.UpdateWinkSetting(userID, request.IsWink)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "設定更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "ウィンク設定を更新しました",
	})
}

// AI設定更新
func UpdateAISetting(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		IsAI bool `json:"is_ai"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := settingRepo.UpdateAISetting(userID, request.IsAI)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "設定更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "AI設定を更新しました",
	})
}

// 位置情報設定更新
func UpdateLocationSetting(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		Location string `json:"location"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	err := settingRepo.UpdateLocationSetting(userID, request.Location)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "設定更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "位置情報設定を更新しました",
	})
}

// 検索履歴取得
func GetSearchHistory(c *gin.Context) {
	userID := c.Param("user_id")

	history, err := searchRepo.GetSearchHistory(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "検索履歴取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"words":  history,
	})
}

// 単語検索
func SearchByWord(c *gin.Context) {
	word := c.Param("word")

	recipes, err := searchRepo.SearchByWord(word)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "検索に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"recipes": recipes,
	})
}

// カテゴリ検索
func SearchByCategory(c *gin.Context) {
	categoryID := c.Param("category_id")

	recipes, err := searchRepo.SearchByCategory(categoryID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "検索に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"recipes": recipes,
	})
}
