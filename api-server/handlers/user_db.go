package handlers

import (
	"api-server/models"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// ユーザー作成（Supabase版）
func CreateUserDB(c *gin.Context) {
	var user models.User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	// ユーザーIDを生成（簡易的な実装）
	userID := fmt.Sprintf("%d", time.Now().Unix())
	user.UserID = userID

	result, err := models.DB.CreateUser(user)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.UserResponse{
		Status: 200,
		UserID: result.UserID,
	})
}

// ユーザー取得（Supabase版）
func GetUserDB(c *gin.Context) {
	userID := c.Param("user_id")

	user, err := models.DB.GetUser(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.UserResponse{
		Status:      200,
		Username:    user.Username,
		MailAddress: user.MailAddress,
		Profile:     user.Profile,
		Icon:        user.Icon,
		IsWink:      user.IsWink,
		Location:    user.Location,
		IsAI:        user.IsAI,
	})
}

// ユーザー削除（Supabase版）
func DeleteUserDB(c *gin.Context) {
	userID := c.Param("user_id")

	err := models.DB.DeleteUser(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ユーザーを削除しました",
	})
}

// ユーザーログイン（Supabase版）
func LoginUserDB(c *gin.Context) {
	var request struct {
		UserID       string `json:"user_id"`
		PasswordHash string `json:"password_hash"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	_, err := models.DB.LoginUser(request.UserID, request.PasswordHash)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ログイン完了しました",
	})
}

// ユーザープロフィール更新（Supabase版）
func UpdateUserProfileDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		UserID  string `json:"user_id"`
		Profile string `json:"profile"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	updates := map[string]interface{}{
		"profile": request.Profile,
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
		Message: "プロフィールを更新しました",
	})
}

// ユーザーパスワード更新（Supabase版）
func UpdateUserPasswordDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		UserID       string `json:"user_id"`
		PasswordHash string `json:"password_hash"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	updates := map[string]interface{}{
		"password_hash": request.PasswordHash,
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
		Message: "パスワードを更新しました",
	})
}

// ユーザーアイコン更新（Supabase版）
func UpdateUserIconDB(c *gin.Context) {
	userID := c.Param("user_id")

	var request struct {
		UserID string `json:"user_id"`
		Icon   string `json:"Icon"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, models.Response{
			Status:  400,
			Message: "エラーが発生しました",
		})
		return
	}

	updates := map[string]interface{}{
		"icon": request.Icon,
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
		Message: "アイコンを更新しました",
	})
}
