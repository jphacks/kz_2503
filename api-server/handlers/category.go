package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// カテゴリ一覧取得
func GetCategories(c *gin.Context) {
	models.MockDB.Mu.RLock()
	categories := models.MockDB.Categories
	models.MockDB.Mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"status":   200,
		"category": categories,
	})
}
