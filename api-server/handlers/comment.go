package handlers

import (
	"api-server/models"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// コメント作成
func CreateComment(c *gin.Context) {
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

	// コメントIDを生成
	commentID := fmt.Sprintf("comment_%d", time.Now().Unix())
	comment := models.Comment{
		CommentID: commentID,
		UserID:    request.UserID,
		RecipeID:  recipeID,
		Content:   request.Content,
	}

	models.MockDB.Mu.Lock()
	models.MockDB.Comments[commentID] = comment
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "コメントしました",
	})
}

// コメント更新
func UpdateComment(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	if comment, exists := models.MockDB.Comments[request.CommentID]; exists {
		comment.Content = request.Content
		models.MockDB.Comments[request.CommentID] = comment
		models.MockDB.Mu.Unlock()

		c.JSON(http.StatusOK, models.Response{
			Status:  200,
			Message: "コメントを修正しました",
		})
		return
	}
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusBadRequest, models.Response{
		Status:  400,
		Message: "エラーが発生しました",
	})
}

// コメント削除
func DeleteComment(c *gin.Context) {
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

	models.MockDB.Mu.Lock()
	delete(models.MockDB.Comments, request.CommentID)
	models.MockDB.Mu.Unlock()

	c.JSON(http.StatusOK, models.Response{
		Status:  200,
		Message: "コメントを削除しました",
	})
}
