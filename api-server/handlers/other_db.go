package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// カテゴリ一覧取得（Supabase版）
func GetCategoriesDB(c *gin.Context) {
	categories, err := models.DB.GetCategories()
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":   200,
		"category": categories,
	})
}

// コメント作成（Supabase版）
func CreateCommentDB(c *gin.Context) {
	recipeID := c.Param("recipe_id")

	var request struct {
		UserID  string `json:"user_id"`
		Content string `json:"content"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	comment := models.Comment{
		UserID:   request.UserID,
		RecipeID: recipeID,
		Content:  request.Content,
	}

	_, err := models.DB.CreateComment(comment)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "コメントしました",
	})
}

// コメント更新（Supabase版）
func UpdateCommentDB(c *gin.Context) {
	_ = c.Param("recipe_id") // パラメータは使用しないが、API設計に合わせて保持

	var request struct {
		CommentID string `json:"comment_id"`
		UserID    string `json:"user_id"`
		Content   string `json:"content"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	updates := map[string]interface{}{
		"content": request.Content,
	}

	err := models.DB.UpdateComment(request.CommentID, updates)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "コメントを修正しました",
	})
}

// コメント削除（Supabase版）
func DeleteCommentDB(c *gin.Context) {
	_ = c.Param("recipe_id") // パラメータは使用しないが、API設計に合わせて保持

	var request struct {
		CommentID string `json:"comment_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.DeleteComment(request.CommentID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "コメントを削除しました",
	})
}

// フォロー（Supabase版）
func FollowUserDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		FollowerID string `json:"follower_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.FollowUser(userID, request.FollowerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "フォローしました",
	})
}

// フォロー解除（Supabase版）
func UnfollowUserDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		FollowerID string `json:"follower_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.UnfollowUser(userID, request.FollowerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "フォローを解除しました",
	})
}

// フォロワー一覧取得（Supabase版）
func GetFollowersDB(c *gin.Context) {
	userID := c.Param("user_id")

	followerIDs, err := models.DB.GetFollowers(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	followers := make([]gin.H, len(followerIDs))
	for i, id := range followerIDs {
		followers[i] = gin.H{"user_id": id}
	}

	c.JSON(http.StatusOK, gin.H{
		"status":   200,
		"follower": followers,
	})
}

// ブロック（Supabase版）
func BlockUserDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		BlockerID string `json:"blocker_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.BlockUser(userID, request.BlockerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ブロックしました",
	})
}

// ブロック解除（Supabase版）
func UnblockUserDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		BlockerID string `json:"blocker_id"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	err := models.DB.UnblockUser(userID, request.BlockerID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ブロックを解除しました",
	})
}

// ブロック一覧取得（Supabase版）
func GetBlocksDB(c *gin.Context) {
	userID := c.Param("user_id")

	blockerIDs, err := models.DB.GetBlocks(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	blocks := make([]gin.H, len(blockerIDs))
	for i, id := range blockerIDs {
		blocks[i] = gin.H{"user_id": id}
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"block":  blocks,
	})
}

// 通知取得（Supabase版）
func GetNoticesDB(c *gin.Context) {
	userID := c.Param("user_id")

	notices, err := models.DB.GetNotices(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"notice": notices,
	})
}

// 通知既読更新（Supabase版）
func UpdateNoticeStatusDB(c *gin.Context) {
	_ = c.Param("user_id") // パラメータは使用しないが、API設計に合わせて保持

	var request struct {
		UserID string `json:"user_id"`
		Status string `json:"status"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	isRead := request.Status == "already read"
	err := models.DB.UpdateNoticeStatus(request.UserID, isRead)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "更新完了しました",
	})
}

// 検索履歴取得（Supabase版）
func GetSearchHistoryDB(c *gin.Context) {
	userID := c.Param("user_id")

	words, err := models.DB.GetSearchHistory(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	wordList := make([]gin.H, len(words))
	for i, word := range words {
		wordList[i] = gin.H{"value": word}
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"word":   wordList,
	})
}

// ワード検索（Supabase版）
func SearchByWordDB(c *gin.Context) {
	word := c.Param("word")

	recipes, err := models.DB.SearchByWord(word)
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

// カテゴリ検索（Supabase版）
func SearchByCategoryDB(c *gin.Context) {
	categoryID := c.Param("category_id")

	recipes, err := models.DB.SearchByCategory(categoryID)
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
