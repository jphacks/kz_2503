package models

import "sync"

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
}

// レシピ一覧用の簡易レシピ
type RecipeSummary struct {
	RecipeID   string `json:"recipe_id"`
	Title      string `json:"title"`
	Chef       string `json:"chef"`
	PictureURL string `json:"picture_url"`
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
	UserID       string `json:"user_id"`
	Username     string `json:"username"`
	PasswordHash string `json:"password_hash"`
	MailAddress  string `json:"mailadress"`
	Profile      string `json:"profile"`
	Icon         string `json:"icon"`
	IsWink       bool   `json:"is_wink"`
	Location     string `json:"location"`
	IsAI         bool   `json:"is_ai"`
}

// お気に入りレシピ
type FavoriteRecipe struct {
	UserID   string `json:"user_id"`
	RecipeID string `json:"recipe_id"`
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
	Mu              sync.RWMutex
}

var MockDB *MockData

// モックデータを初期化
func InitMockData() {
	MockDB = &MockData{
		Recipes:         make(map[string]Recipe),
		Users:           make(map[string]User),
		FavoriteRecipes: make(map[string][]string),
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
}
