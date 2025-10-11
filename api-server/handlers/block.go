package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ブロック
func BlockUser(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	// 既にブロックしていないかチェック
	blockers := models.MockDB.Blocks[userID]
	for _, id := range blockers {
		if id == request.BlockerID {
			models.MockDB.Mu.Unlock()
			c.JSON(http.StatusOK, models.Response{
				Status:  200,
				Message: "ブロックしました",
			})
			return
		}
	}

	// ブロックを追加
	models.MockDB.Blocks[userID] = append(blockers, request.BlockerID)
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ブロックしました",
	})
}

// ブロック解除
func UnblockUser(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	blockers := models.MockDB.Blocks[userID]
	for i, id := range blockers {
		if id == request.BlockerID {
			// スライスから削除
			models.MockDB.Blocks[userID] = append(blockers[:i], blockers[i+1:]...)
			break
		}
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ブロックを解除しました",
	})
}

// ブロック一覧取得
func GetBlocks(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	blockerIDs, exists := models.MockDB.Blocks[userID]
	if !exists {
		models.MockDB.Mu.RUnlock()
		c.JSON(http.StatusOK, gin.H{
			"status": 200,
			"block":  []gin.H{},
		})
		return
	}

	blocks := make([]gin.H, len(blockerIDs))
	for i, id := range blockerIDs {
		blocks[i] = gin.H{"user_id": id}
	}
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"block":  blocks,
	})
}
