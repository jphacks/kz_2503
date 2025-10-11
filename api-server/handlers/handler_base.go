package handlers

import "api-server/interfaces"

// ハンドラーのベース構造体
type HandlerBase struct {
	repo interfaces.Repository
}

// 新しいハンドラーベースを作成
func NewHandlerBase(repo interfaces.Repository) *HandlerBase {
	return &HandlerBase{
		repo: repo,
	}
}
