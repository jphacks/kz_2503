package handlers

import (
	"api-server/models"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// ユーザー作成
func CreateUser(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	models.MockDB.Users[userID] = user
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.UserResponse{
		Status: 200,
		UserID: userID,
	})
}

// ユーザー取得
func GetUser(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.RLock()
	user, exists := models.MockDB.Users[userID]
	models.MockDB.Mu.RUnlock()

	if !exists {
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

// ユーザー削除
func DeleteUser(c *gin.Context) {
	userID := c.Param("user_id")

	models.MockDB.Mu.Lock()
	delete(models.MockDB.Users, userID)
	delete(models.MockDB.FavoriteRecipes, userID)
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "ユーザーを削除しました",
	})
}

// ユーザーログイン
func LoginUser(c *gin.Context) {
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

	models.MockDB.Mu.RLock()
	user, exists := models.MockDB.Users[request.UserID]
	models.MockDB.Mu.RUnlock()

	if !exists || user.PasswordHash != request.PasswordHash {
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

// ユーザープロフィール更新
func UpdateUserProfile(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	if user, exists := models.MockDB.Users[userID]; exists {
		user.Profile = request.Profile
		models.MockDB.Users[userID] = user
		models.MockDB.Mu.Unlock()

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "プロフィールを更新しました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}

// ユーザーパスワード更新
func UpdateUserPassword(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	if user, exists := models.MockDB.Users[userID]; exists {
		user.PasswordHash = request.PasswordHash
		models.MockDB.Users[userID] = user
		models.MockDB.Mu.Unlock()

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "パスワードを更新しました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}

// ユーザーアイコン更新
func UpdateUserIcon(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	if user, exists := models.MockDB.Users[userID]; exists {
		user.Icon = request.Icon
		models.MockDB.Users[userID] = user
		models.MockDB.Mu.Unlock()

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "アイコンを更新しました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}
