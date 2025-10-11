package models

import (
	"api-server/config"
	"time"

	"github.com/supabase-community/supabase-go"
)

// データベース操作用の構造体
type Database struct {
	Client *supabase.Client
}

var DB *Database

// InitDatabase データベース接続を初期化
func InitDatabase() {
	DB = &Database{
		Client: config.SupabaseClient,
	}
}

// ユーザー関連のデータベース操作
func (db *Database) CreateUser(user User) (*User, error) {
	var result []User
	_, _, err := db.Client.From("users").Insert(user, false, "", "", "").Execute(&result)
	if err != nil {
		return nil, err
	}
	if len(result) > 0 {
		return &result[0], nil
	}
	return nil, err
}

func (db *Database) GetUser(userID string) (*User, error) {
	var result []User
	_, _, err := db.Client.From("users").Select("*", "", false).Eq("id", userID).Single().Execute(&result)
	if err != nil {
		return nil, err
	}
	if len(result) > 0 {
		return &result[0], nil
	}
	return nil, err
}

func (db *Database) UpdateUser(userID string, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()
	_, _, err := db.Client.From("users").Update(updates, "", "").Eq("id", userID).Execute(nil)
	return err
}

func (db *Database) DeleteUser(userID string) error {
	_, _, err := db.Client.From("users").Delete("", "").Eq("id", userID).Execute(nil)
	return err
}

func (db *Database) LoginUser(userID, passwordHash string) (*User, error) {
	var result []User
	_, _, err := db.Client.From("users").Select("*", "", false).Eq("id", userID).Eq("password_hash", passwordHash).Single().Execute(&result)
	if err != nil {
		return nil, err
	}
	if len(result) > 0 {
		return &result[0], nil
	}
	return nil, err
}

// レシピ関連のデータベース操作
func (db *Database) CreateRecipe(recipe Recipe) (*Recipe, error) {
	var result Recipe
	err := db.Client.From("recipes").Insert(recipe).Execute(&result)
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (db *Database) GetRecipe(recipeID string) (*Recipe, error) {
	var result Recipe
	err := db.Client.From("recipes").Select("*").Eq("id", recipeID).Single().Execute(&result)
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (db *Database) UpdateRecipe(recipeID string, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()
	err := db.Client.From("recipes").Update(updates).Eq("id", recipeID).Execute(nil)
	return err
}

func (db *Database) DeleteRecipe(recipeID string) error {
	err := db.Client.From("recipes").Delete().Eq("id", recipeID).Execute(nil)
	return err
}

func (db *Database) GetPopularRecipes() ([]RecipeSummary, error) {
	var results []RecipeSummary
	err := db.Client.From("recipes").
		Select("id, title, picture_url, user_id").
		Order("created_at", false).
		Limit(10).
		Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func (db *Database) GetUserRecipes(userID string) ([]RecipeSummary, error) {
	var results []RecipeSummary
	err := db.Client.From("recipes").
		Select("id, title, picture_url, user_id").
		Eq("user_id", userID).
		Order("created_at", false).
		Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func (db *Database) GetFavoriteRecipes(userID string) ([]RecipeSummary, error) {
	var results []RecipeSummary
	err := db.Client.From("favorite_recipes").
		Select("recipes(id, title, picture_url, user_id)").
		Eq("user_id", userID).
		Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func (db *Database) AddFavoriteRecipe(userID, recipeID string) error {
	_, err := db.Client.From("favorite_recipes").Insert(map[string]interface{}{
		"user_id":   userID,
		"recipe_id": recipeID,
	}).Execute(nil)
	return err
}

func (db *Database) RemoveFavoriteRecipe(userID, recipeID string) error {
	err := db.Client.From("favorite_recipes").
		Delete().
		Eq("user_id", userID).
		Eq("recipe_id", recipeID).
		Execute(nil)
	return err
}

// カテゴリ関連のデータベース操作
func (db *Database) GetCategories() ([]Category, error) {
	var results []Category
	err := db.Client.From("categories").Select("*").Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

// コメント関連のデータベース操作
func (db *Database) CreateComment(comment Comment) (*Comment, error) {
	var result Comment
	err := db.Client.From("comments").Insert(comment).Execute(&result)
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (db *Database) UpdateComment(commentID string, updates map[string]interface{}) error {
	updates["updated_at"] = time.Now()
	err := db.Client.From("comments").Update(updates).Eq("id", commentID).Execute(nil)
	return err
}

func (db *Database) DeleteComment(commentID string) error {
	err := db.Client.From("comments").Delete().Eq("id", commentID).Execute(nil)
	return err
}

// フォロー関連のデータベース操作
func (db *Database) FollowUser(userID, followerID string) error {
	_, err := db.Client.From("follows").Insert(map[string]interface{}{
		"user_id":     userID,
		"follower_id": followerID,
	}).Execute(nil)
	return err
}

func (db *Database) UnfollowUser(userID, followerID string) error {
	err := db.Client.From("follows").
		Delete().
		Eq("user_id", userID).
		Eq("follower_id", followerID).
		Execute(nil)
	return err
}

func (db *Database) GetFollowers(userID string) ([]string, error) {
	var results []struct {
		FollowerID string `json:"follower_id"`
	}
	err := db.Client.From("follows").
		Select("follower_id").
		Eq("user_id", userID).
		Execute(&results)
	if err != nil {
		return nil, err
	}

	followerIDs := make([]string, len(results))
	for i, result := range results {
		followerIDs[i] = result.FollowerID
	}
	return followerIDs, nil
}

// ブロック関連のデータベース操作
func (db *Database) BlockUser(userID, blockerID string) error {
	_, err := db.Client.From("blocks").Insert(map[string]interface{}{
		"user_id":    userID,
		"blocker_id": blockerID,
	}).Execute(nil)
	return err
}

func (db *Database) UnblockUser(userID, blockerID string) error {
	err := db.Client.From("blocks").
		Delete().
		Eq("user_id", userID).
		Eq("blocker_id", blockerID).
		Execute(nil)
	return err
}

func (db *Database) GetBlocks(userID string) ([]string, error) {
	var results []struct {
		BlockerID string `json:"blocker_id"`
	}
	err := db.Client.From("blocks").
		Select("blocker_id").
		Eq("user_id", userID).
		Execute(&results)
	if err != nil {
		return nil, err
	}

	blockerIDs := make([]string, len(results))
	for i, result := range results {
		blockerIDs[i] = result.BlockerID
	}
	return blockerIDs, nil
}

// 通知関連のデータベース操作
func (db *Database) GetNotices(userID string) ([]Notice, error) {
	var results []Notice
	err := db.Client.From("notices").
		Select("*").
		Eq("user_id", userID).
		Order("created_at", false).
		Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func (db *Database) UpdateNoticeStatus(userID string, isRead bool) error {
	err := db.Client.From("notices").
		Update(map[string]interface{}{"is_read": isRead}).
		Eq("user_id", userID).
		Execute(nil)
	return err
}

// 検索関連のデータベース操作
func (db *Database) GetSearchHistory(userID string) ([]string, error) {
	var results []struct {
		Word string `json:"word"`
	}
	err := db.Client.From("search_histories").
		Select("word").
		Eq("user_id", userID).
		Order("created_at", false).
		Limit(10).
		Execute(&results)
	if err != nil {
		return nil, err
	}

	words := make([]string, len(results))
	for i, result := range results {
		words[i] = result.Word
	}
	return words, nil
}

func (db *Database) SearchByWord(word string) ([]RecipeSummary, error) {
	var results []RecipeSummary
	err := db.Client.From("recipes").
		Select("id, title, picture_url, user_id").
		Like("title", "%"+word+"%").
		Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func (db *Database) SearchByCategory(categoryID string) ([]RecipeSummary, error) {
	var results []RecipeSummary
	err := db.Client.From("recipes").
		Select("id, title, picture_url, user_id").
		Eq("category_id", categoryID).
		Execute(&results)
	if err != nil {
		return nil, err
	}
	return results, nil
}

func (db *Database) AddSearchHistory(userID, word string) error {
	_, err := db.Client.From("search_histories").Insert(map[string]interface{}{
		"user_id": userID,
		"word":    word,
	}).Execute(nil)
	return err
}
