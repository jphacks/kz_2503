package handlers

import (
	"api-server/interfaces"
	"api-server/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// グローバルなリポジトリインスタンス
var userRepo interfaces.Repository

// ユーザーハンドラーを初期化
func InitUserHandler(repo interfaces.Repository) {
	userRepo = repo
}

// ユーザー作成
func CreateUser(c *gin.Context) {
	var request models.User
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	user, err := userRepo.CreateUser(request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": 500, "message": "ユーザー作成に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"user":   user,
	})
}

// ユーザー取得
func GetUser(c *gin.Context) {
	userID := c.Param("user_id")

	user, err := userRepo.GetUser(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"user":   user,
	})
}

// メールアドレスでユーザー存在確認
func GetUserByEmail(c *gin.Context) {
	email := c.Param("email")

	user, err := userRepo.GetUserByEmail(email)
	if err != nil {
		// ユーザーが見つからない場合は202を返す
		c.JSON(http.StatusAccepted, gin.H{
			"status":  202,
			"message": "アカウントが存在しません",
		})
		return
	}

	// ユーザーが見つかった場合は200を返す
	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"user_id": user.UserID,
	})
}

// ユーザー削除
func DeleteUser(c *gin.Context) {
	userID := c.Param("user_id")

	err := userRepo.DeleteUser(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "ユーザーを削除しました",
	})
}

// ユーザーログイン
func LoginUser(c *gin.Context) {
	var request struct {
		UserID       string `json:"user_id"`
		PasswordHash string `json:"password_hash"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	user, err := userRepo.LoginUser(request.UserID, request.PasswordHash)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"status": 401, "message": "認証に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status": 200,
		"user":   user,
	})
}

// ユーザープロフィール更新
func UpdateUserProfile(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		Username string `json:"username"`
		Profile  string `json:"profile"`
		Icon     string `json:"icon"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	updates := map[string]interface{}{
		"username": request.Username,
		"profile":  request.Profile,
		"icon":     request.Icon,
	}

	err := userRepo.UpdateUser(userID, updates)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "プロフィールを更新しました",
	})
}

// ユーザーパスワード更新
func UpdateUserPassword(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		PasswordHash string `json:"password_hash"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	updates := map[string]interface{}{
		"password_hash": request.PasswordHash,
	}

	err := userRepo.UpdateUser(userID, updates)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "パスワードを更新しました",
	})
}

// ユーザーアイコン更新
func UpdateUserIcon(c *gin.Context) {
	userID := c.Param("user_id")
	var request struct {
		Icon string `json:"icon"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": 400, "message": "リクエストが無効です"})
		return
	}

	updates := map[string]interface{}{
		"icon": request.Icon,
	}

	err := userRepo.UpdateUser(userID, updates)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": 404, "message": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":  200,
		"message": "アイコンを更新しました",
	})
}
