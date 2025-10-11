package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// フォロー
func FollowUser(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	// 既にフォローしていないかチェック
	followers := models.MockDB.Follows[userID]
	for _, id := range followers {
		if id == request.FollowerID {
			models.MockDB.Mu.Unlock()
			c.JSON(http.StatusOK, models.Response{
				Status:  200,
				Message: "フォローしました",
			})
			return
		}
	}

	// フォローを追加
	models.MockDB.Follows[userID] = append(followers, request.FollowerID)
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "フォローしました",
	})
}

// フォロー解除
func UnfollowUser(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	followers := models.MockDB.Follows[userID]
	for i, id := range followers {
		if id == request.FollowerID {
			// スライスから削除
			models.MockDB.Follows[userID] = append(followers[:i], followers[i+1:]...)
			break
		}
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "フォローを解除しました",
	})
}

// フォロワー一覧取得
func GetFollowers(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	followerIDs, exists := models.MockDB.Follows[userID]
	if !exists {
		models.MockDB.Mu.RUnlock()
		c.JSON(http.StatusOK, gin.H{
			"status":   200,
			"follower": []gin.H{},
		})
		return
	}

	followers := make([]gin.H, len(followerIDs))
	for i, id := range followerIDs {
		followers[i] = gin.H{"user_id": id}
	}
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"status":   200,
		"follower": followers,
	})
}
