package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ウィンク設定更新
func UpdateWinkSetting(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		IsWink bool `json:"is_wink"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	models.MockDB.Mu.Lock()
	if user, exists := models.MockDB.Users[userID]; exists {
		user.IsWink = request.IsWink
		models.MockDB.Users[userID] = user
		models.MockDB.Mu.Unlock()

		status := "OFF"
		if request.IsWink {
			status = "ON"
		}

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "ウィンクスイッチを " + status + " にしました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}

// AI設定更新
func UpdateAISetting(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		IsAI bool `json:"is_ai"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	models.MockDB.Mu.Lock()
	if user, exists := models.MockDB.Users[userID]; exists {
		user.IsAI = request.IsAI
		models.MockDB.Users[userID] = user
		models.MockDB.Mu.Unlock()

		status := "OFF"
		if request.IsAI {
			status = "ON"
		}

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "AI モードを " + status + " にしました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}

// 地域設定更新
func UpdateLocationSetting(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		Location string `json:"location"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	models.MockDB.Mu.Lock()
	if user, exists := models.MockDB.Users[userID]; exists {
		user.Location = request.Location
		models.MockDB.Users[userID] = user
		models.MockDB.Mu.Unlock()

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "地域を " + request.Location + " にしました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}
