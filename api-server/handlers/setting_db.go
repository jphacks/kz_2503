package handlers

import (
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ウィンク設定更新（Supabase版）
func UpdateWinkSettingDB(c *gin.Context) {
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

	updates := map[string]interface{}{
		"is_wink": request.IsWink,
	}

	err := models.DB.UpdateUser(userID, updates)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	status := "OFF"
	if request.IsWink {
		status = "ON"
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ウィンクスイッチを " + status + " にしました",
	})
}

// AI設定更新（Supabase版）
func UpdateAISettingDB(c *gin.Context) {
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

	updates := map[string]interface{}{
		"is_ai": request.IsAI,
	}

	err := models.DB.UpdateUser(userID, updates)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	status := "OFF"
	if request.IsAI {
		status = "ON"
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "AI モードを " + status + " にしました",
	})
}

// 地域設定更新（Supabase版）
func UpdateLocationSettingDB(c *gin.Context) {
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

	updates := map[string]interface{}{
		"location": request.Location,
	}

	err := models.DB.UpdateUser(userID, updates)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "地域を " + request.Location + " にしました",
	})
}
