package models

import (
	"sync"
	"time"
)

// レシピ材料
type RecipeMaterial struct {
	MaterialName  string `json:"material_name"`
	MaterialCount string `json:"material_count"`
	MaterialUnit  string `json:"material_unit,omitempty"`
}

// レシピ手順
type RecipeContent struct {
	PictureURL  string `json:"picture_url"`
	Step        int    `json:"step"`
	Description string `json:"description"`
}

// レシピ
type Recipe struct {
	RecipeID       string           `json:"recipe_id"`
	UserID         string           `json:"user_id"`
	CategoryID     string           `json:"category_id"`
	Status         string           `json:"status"`
	Title          string           `json:"title"`
	PictureURL     string           `json:"picture_url"`
	Point          string           `json:"point"`
	ServingCount   int              `json:"serving_count"`
	RecipeMaterial []RecipeMaterial `json:"recipe_material"`
	RecipeContent  []RecipeContent  `json:"recipe_content"`
	CreatedAt      time.Time        `json:"created_at"`
	UpdatedAt      time.Time        `json:"updated_at"`
}

// レシピ一覧用の簡易レシピ
type RecipeSummary struct {
	RecipeID     string `json:"recipe_id"`
	UserID       string `json:"user_id"`
	CategoryID   string `json:"category_id"`
	Status       string `json:"status"`
	Title        string `json:"title"`
	Chef         string `json:"chef"`
	PictureURL   string `json:"picture_url"`
	ServingCount int    `json:"serving_count"`
}

// 週間レシピ
type WeeklyRecipe struct {
	RecipeID   string `json:"recipe_id"`
	Title      string `json:"title"`
	Chef       string `json:"chef"`
	PictureURL string `json:"picture_url"`
}

// 週間レシピレスポンス
type WeeklyRecipesResponse struct {
	Status    int           `json:"status"`
	Sunday    *WeeklyRecipe `json:"Sunday,omitempty"`
	Monday    *WeeklyRecipe `json:"Monday,omitempty"`
	Tuesday   *WeeklyRecipe `json:"Tuesday,omitempty"`
	Wednesday *WeeklyRecipe `json:"Wednesday,omitempty"`
	Thursday  *WeeklyRecipe `json:"Thursday,omitempty"`
	Friday    *WeeklyRecipe `json:"Friday,omitempty"`
	Saturday  *WeeklyRecipe `json:"Saturday,omitempty"`
}

// ユーザー
type User struct {
	UserID       string    `json:"user_id"`
	Username     string    `json:"username"`
	PasswordHash string    `json:"password_hash"`
	MailAddress  string    `json:"mailadress"`
	Profile      string    `json:"profile"`
	Icon         string    `json:"icon"`
	IsWink       bool      `json:"is_wink"`
	Location     string    `json:"location"`
	IsAI         bool      `json:"is_ai"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// お気に入りレシピ
type FavoriteRecipe struct {
	UserID   string `json:"user_id"`
	RecipeID string `json:"recipe_id"`
}

// カテゴリ
type Category struct {
	Value string `json:"value"`
}

// コメント
type Comment struct {
	CommentID string `json:"comment_id"`
	UserID    string `json:"user_id"`
	RecipeID  string `json:"recipe_id"`
	Content   string `json:"content"`
}

// フォロー関係
type Follow struct {
	UserID     string `json:"user_id"`
	FollowerID string `json:"follower_id"`
}

// ブロック関係
type Block struct {
	UserID    string `json:"user_id"`
	BlockerID string `json:"blocker_id"`
}

// 通知
type Notice struct {
	Title   string `json:"title"`
	Content string `json:"content"`
}

// 検索履歴
type SearchHistory struct {
	UserID string `json:"user_id"`
	Word   string `json:"word"`
}

// レスポンス用の構造体
type Response struct {
	Status  int    `json:"status"`
	Message string `json:"message"`
}

type UserResponse struct {
	Status      int    `json:"status"`
	UserID      string `json:"user_id,omitempty"`
	Username    string `json:"username,omitempty"`
	MailAddress string `json:"mailadress,omitempty"`
	Profile     string `json:"profile,omitempty"`
	Icon        string `json:"icon,omitempty"`
	IsWink      bool   `json:"is_wink,omitempty"`
	Location    string `json:"location,omitempty"`
	IsAI        bool   `json:"is_ai,omitempty"`
}

type RecipeResponse struct {
	Status         int              `json:"status"`
	UserID         string           `json:"user_id,omitempty"`
	CategoryID     string           `json:"category_id,omitempty"`
	StatusField    string           `json:"status,omitempty"`
	Title          string           `json:"title,omitempty"`
	PictureURL     string           `json:"picture_url,omitempty"`
	Point          string           `json:"point,omitempty"`
	ServingCount   int              `json:"serving_count,omitempty"`
	RecipeMaterial []RecipeMaterial `json:"recipe_material,omitempty"`
	RecipeContent  []RecipeContent  `json:"recipe_content,omitempty"`
}

type RecipesResponse struct {
	Status  int             `json:"status"`
	Recipes []RecipeSummary `json:"recipes,omitempty"`
}

// モックデータストレージ
type MockData struct {
	Recipes         map[string]Recipe
	Users           map[string]User
	FavoriteRecipes map[string][]string // user_id -> recipe_ids
	Categories      []Category
	Comments        map[string]Comment  // comment_id -> comment
	Follows         map[string][]string // user_id -> follower_ids
	Blocks          map[string][]string // user_id -> blocker_ids
	Notices         map[string][]Notice // user_id -> notices
	SearchHistory   map[string][]string // user_id -> search_words
	Mu              sync.RWMutex
}

var MockDB *MockData

// モックデータを初期化
func InitMockData() {
	MockDB = &MockData{
		Recipes:         make(map[string]Recipe),
		Users:           make(map[string]User),
		FavoriteRecipes: make(map[string][]string),
		Categories:      []Category{},
		Comments:        make(map[string]Comment),
		Follows:         make(map[string][]string),
		Blocks:          make(map[string][]string),
		Notices:         make(map[string][]Notice),
		SearchHistory:   make(map[string][]string),
	}

	// サンプルユーザーを作成
	MockDB.Users["123"] = User{
		UserID:       "123",
		Username:     "kota",
		PasswordHash: "123",
		MailAddress:  "akokoa1221@gmail.com",
		Profile:      "金沢の主婦です",
		Icon:         "https://imgur.com/a/dsfJeyk",
		IsWink:       true,
		Location:     "Japan",
		IsAI:         true,
	}

	// サンプルレシピを作成
	MockDB.Recipes["123"] = Recipe{
		RecipeID:     "123",
		UserID:       "123",
		CategoryID:   "123",
		Status:       "open",
		Title:        "カレー",
		PictureURL:   "https://imgur.com/a/dsfJeyk",
		Point:        "こんにゃくを入れます",
		ServingCount: 2,
		RecipeMaterial: []RecipeMaterial{
			{
				MaterialName:  "人参",
				MaterialCount: "2",
				MaterialUnit:  "本",
			},
		},
		RecipeContent: []RecipeContent{
			{
				PictureURL:  "https://imgur.com/a/dsfJeyk",
				Step:        1,
				Description: "人参を切ります",
			},
		},
	}

	// お気に入りレシピを追加
	MockDB.FavoriteRecipes["123"] = []string{"123"}

	// サンプルカテゴリを作成
	MockDB.Categories = []Category{
		{Value: "サラダ"},
		{Value: "スープ"},
		{Value: "メイン"},
		{Value: "デザート"},
		{Value: "飲み物"},
	}

	// サンプルコメントを作成
	MockDB.Comments["comment_1"] = Comment{
		CommentID: "comment_1",
		UserID:    "123",
		RecipeID:  "123",
		Content:   "とても美味しかったです！",
	}

	// サンプルフォロー関係を作成
	MockDB.Follows["123"] = []string{"456"}

	// サンプル通知を作成
	MockDB.Notices["123"] = []Notice{
		{
			Title:   "フォロー通知",
			Content: "なぎささんからフォローされました",
		},
	}

	// サンプル検索履歴を作成
	MockDB.SearchHistory["123"] = []string{"とうもろこし", "カレー", "サラダ"}
}
