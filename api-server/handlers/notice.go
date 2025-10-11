package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// 通知取得
func GetNotices(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	notices, exists := models.MockDB.Notices[userID]
	if !exists {
		models.MockDB.Mu.RUnlock()
		c.JSON(http.StatusOK, gin.H{
			"status": 200,
			"notice": []models.Notice{},
		})
		return
	}
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"notice": notices,
	})
}

// 通知既読更新
func UpdateNoticeStatus(c *gin.Context) {
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

	// モック実装では、既読状態の管理は簡易的に実装
	// 実際の実装では、通知の既読状態を個別に管理する必要がある
	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "更新完了しました",
	})
}
