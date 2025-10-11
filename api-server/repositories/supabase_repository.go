package repositories

import (
	"api-server/interfaces"
	"api-server/models"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

type SupabaseRepository struct {
	baseURL string
	apiKey  string
}

func NewSupabaseRepository() interfaces.Repository {
	// 環境変数から直接取得
	baseURL := os.Getenv("SUPABASE_URL")
	apiKey := os.Getenv("SUPABASE_ANON_KEY")

	return &SupabaseRepository{
		baseURL: baseURL,
		apiKey:  apiKey,
	}
}

// 共通のHTTPリクエスト処理
func (r *SupabaseRepository) makeRequest(method, endpoint string, body interface{}) ([]map[string]interface{}, error) {
	var reqBody io.Reader
	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reqBody = strings.NewReader(string(jsonData))
	}

	req, err := http.NewRequest(method, endpoint, reqBody)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.apiKey)
	req.Header.Set("Authorization", "Bearer "+r.apiKey)

	// POSTリクエストの場合は作成されたレコードを返すように指定
	if method == "POST" {
		req.Header.Set("Prefer", "return=representation")
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(respBody))
	}

	var result []map[string]interface{}
	if len(respBody) > 0 {
		if err := json.Unmarshal(respBody, &result); err != nil {
			return nil, fmt.Errorf("JSON parse error: %v, body: %s", err, string(respBody))
		}
	}

	return result, nil
}

// ユーザー関連
func (r *SupabaseRepository) CreateUser(user models.User) (*models.User, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/users", r.baseURL)

	// Supabaseに送信するデータ構造を作成
	userData := map[string]interface{}{
		"username":      user.Username,
		"password_hash": user.PasswordHash,
		"mail_address":  user.MailAddress,
		"profile":       user.Profile,
		"icon":          user.Icon,
		"is_wink":       user.IsWink,
		"location":      user.Location,
		"is_ai":         user.IsAI,
	}

	results, err := r.makeRequest("POST", endpoint, userData)
	if err != nil {
		return nil, err
	}
	if len(results) > 0 {
		// map[string]interface{}をUserに変換
		userData := results[0]
		user.UserID = userData["id"].(string)
		user.Username = userData["username"].(string)
		user.MailAddress = userData["mail_address"].(string)
		if profile, ok := userData["profile"].(string); ok {
			user.Profile = profile
		}
		if icon, ok := userData["icon"].(string); ok {
			user.Icon = icon
		}
		if isWink, ok := userData["is_wink"].(bool); ok {
			user.IsWink = isWink
		}
		if location, ok := userData["location"].(string); ok {
			user.Location = location
		}
		if isAI, ok := userData["is_ai"].(bool); ok {
			user.IsAI = isAI
		}
		return &user, nil
	}
	return nil, fmt.Errorf("no result returned")
}

func (r *SupabaseRepository) GetUser(userID string) (*models.User, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/users?id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	if len(results) > 0 {
		userData := results[0]
		user := models.User{
			UserID:       userData["id"].(string),
			Username:     userData["username"].(string),
			PasswordHash: userData["password_hash"].(string),
			MailAddress:  userData["mail_address"].(string),
		}
		if profile, ok := userData["profile"].(string); ok {
			user.Profile = profile
		}
		if icon, ok := userData["icon"].(string); ok {
			user.Icon = icon
		}
		if isWink, ok := userData["is_wink"].(bool); ok {
			user.IsWink = isWink
		}
		if location, ok := userData["location"].(string); ok {
			user.Location = location
		}
		if isAI, ok := userData["is_ai"].(bool); ok {
			user.IsAI = isAI
		}
		return &user, nil
	}
	return nil, fmt.Errorf("user not found")
}

func (r *SupabaseRepository) GetUserByEmail(email string) (*models.User, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/users?mail_address=eq.%s", r.baseURL, email)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	if len(results) > 0 {
		userData := results[0]
		user := models.User{
			UserID:       userData["id"].(string),
			Username:     userData["username"].(string),
			PasswordHash: userData["password_hash"].(string),
			MailAddress:  userData["mail_address"].(string),
		}
		if profile, ok := userData["profile"].(string); ok {
			user.Profile = profile
		}
		if icon, ok := userData["icon"].(string); ok {
			user.Icon = icon
		}
		if isWink, ok := userData["is_wink"].(bool); ok {
			user.IsWink = isWink
		}
		if location, ok := userData["location"].(string); ok {
			user.Location = location
		}
		if isAI, ok := userData["is_ai"].(bool); ok {
			user.IsAI = isAI
		}
		return &user, nil
	}
	return nil, fmt.Errorf("user not found")
}

func (r *SupabaseRepository) UpdateUser(userID string, updates map[string]interface{}) error {
	endpoint := fmt.Sprintf("%s/rest/v1/users?id=eq.%s", r.baseURL, userID)
	_, err := r.makeRequest("PATCH", endpoint, updates)
	return err
}

func (r *SupabaseRepository) DeleteUser(userID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/users?id=eq.%s", r.baseURL, userID)
	_, err := r.makeRequest("DELETE", endpoint, nil)
	return err
}

func (r *SupabaseRepository) LoginUser(userID, passwordHash string) (*models.User, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/users?id=eq.%s&password_hash=eq.%s", r.baseURL, userID, passwordHash)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	if len(results) > 0 {
		userData := results[0]
		user := models.User{
			UserID:       userData["id"].(string),
			Username:     userData["username"].(string),
			PasswordHash: userData["password_hash"].(string),
			MailAddress:  userData["mail_address"].(string),
		}
		if profile, ok := userData["profile"].(string); ok {
			user.Profile = profile
		}
		if icon, ok := userData["icon"].(string); ok {
			user.Icon = icon
		}
		if isWink, ok := userData["is_wink"].(bool); ok {
			user.IsWink = isWink
		}
		if location, ok := userData["location"].(string); ok {
			user.Location = location
		}
		if isAI, ok := userData["is_ai"].(bool); ok {
			user.IsAI = isAI
		}
		return &user, nil
	}
	return nil, fmt.Errorf("invalid credentials")
}

// レシピ関連
func (r *SupabaseRepository) CreateRecipe(recipe models.Recipe) (*models.Recipe, error) {
	// メインレシピデータ（子テーブルを除く）
	recipeData := map[string]interface{}{
		"user_id":       recipe.UserID,
		"category_id":   recipe.CategoryID,
		"status":        recipe.Status,
		"title":         recipe.Title,
		"picture_url":   recipe.PictureURL,
		"point":         recipe.Point,
		"serving_count": recipe.ServingCount,
	}

	endpoint := fmt.Sprintf("%s/rest/v1/recipes", r.baseURL)

	// デバッグ情報を出力
	fmt.Printf("DEBUG: Creating recipe at endpoint: %s\n", endpoint)
	fmt.Printf("DEBUG: Recipe data: %+v\n", recipeData)

	results, err := r.makeRequest("POST", endpoint, recipeData)
	if err != nil {
		fmt.Printf("DEBUG: Error in makeRequest: %v\n", err)
		return nil, err
	}

	fmt.Printf("DEBUG: Results: %+v\n", results)

	if len(results) > 0 {
		createdRecipeData := results[0]
		recipe.RecipeID = createdRecipeData["id"].(string)
		recipe.UserID = createdRecipeData["user_id"].(string)
		recipe.CategoryID = createdRecipeData["category_id"].(string)
		recipe.Title = createdRecipeData["title"].(string)
		recipe.Status = createdRecipeData["status"].(string)
		if point, ok := createdRecipeData["point"].(string); ok {
			recipe.Point = point
		}
		if pictureURL, ok := createdRecipeData["picture_url"].(string); ok {
			recipe.PictureURL = pictureURL
		}
		if servingCount, ok := createdRecipeData["serving_count"].(float64); ok {
			recipe.ServingCount = int(servingCount)
		}

		// レシピ材料を別テーブルに保存
		if len(recipe.RecipeMaterial) > 0 {
			for _, material := range recipe.RecipeMaterial {
				materialData := map[string]interface{}{
					"recipe_id":      recipe.RecipeID,
					"material_name":  material.MaterialName,
					"material_count": material.MaterialCount,
					"material_unit":  material.MaterialUnit,
				}
				materialEndpoint := fmt.Sprintf("%s/rest/v1/recipe_materials", r.baseURL)
				_, err := r.makeRequest("POST", materialEndpoint, materialData)
				if err != nil {
					fmt.Printf("DEBUG: Error creating material: %v\n", err)
					// 材料の作成に失敗してもレシピは作成済みなので続行
				}
			}
		}

		// レシピ手順を別テーブルに保存
		if len(recipe.RecipeContent) > 0 {
			for _, content := range recipe.RecipeContent {
				contentData := map[string]interface{}{
					"recipe_id":   recipe.RecipeID,
					"picture_url": content.PictureURL,
					"step":        content.Step,
					"description": content.Description,
				}
				contentEndpoint := fmt.Sprintf("%s/rest/v1/recipe_contents", r.baseURL)
				_, err := r.makeRequest("POST", contentEndpoint, contentData)
				if err != nil {
					fmt.Printf("DEBUG: Error creating content: %v\n", err)
					// 手順の作成に失敗してもレシピは作成済みなので続行
				}
			}
		}

		return &recipe, nil
	}
	return nil, fmt.Errorf("no result returned")
}

func (r *SupabaseRepository) GetRecipe(recipeID string) (*models.Recipe, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes?id=eq.%s", r.baseURL, recipeID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	if len(results) > 0 {
		recipeData := results[0]
		recipe := models.Recipe{
			RecipeID:   recipeData["id"].(string),
			UserID:     recipeData["user_id"].(string),
			CategoryID: recipeData["category_id"].(string),
			Title:      recipeData["title"].(string),
			Status:     recipeData["status"].(string),
		}
		if point, ok := recipeData["point"].(string); ok {
			recipe.Point = point
		}
		if pictureURL, ok := recipeData["picture_url"].(string); ok {
			recipe.PictureURL = pictureURL
		}
		if servingCount, ok := recipeData["serving_count"].(float64); ok {
			recipe.ServingCount = int(servingCount)
		}
		return &recipe, nil
	}
	return nil, fmt.Errorf("recipe not found")
}

func (r *SupabaseRepository) UpdateRecipe(recipeID string, updates map[string]interface{}) error {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes?id=eq.%s", r.baseURL, recipeID)
	_, err := r.makeRequest("PATCH", endpoint, updates)
	return err
}

func (r *SupabaseRepository) DeleteRecipe(recipeID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes?id=eq.%s", r.baseURL, recipeID)
	_, err := r.makeRequest("DELETE", endpoint, nil)
	return err
}

func (r *SupabaseRepository) GetPopularRecipes() ([]models.Recipe, error) {
	// serving_countで降順ソートして人気レシピを取得
	endpoint := fmt.Sprintf("%s/rest/v1/recipes?order=serving_count.desc", r.baseURL)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var recipes []models.Recipe
	for _, recipeData := range results {
		recipe := models.Recipe{
			RecipeID:       recipeData["id"].(string),
			UserID:         recipeData["user_id"].(string),
			CategoryID:     recipeData["category_id"].(string),
			Title:          recipeData["title"].(string),
			Status:         recipeData["status"].(string),
			RecipeMaterial: []models.RecipeMaterial{}, // 空配列で初期化
			RecipeContent:  []models.RecipeContent{},  // 空配列で初期化
			CreatedAt:      time.Now(),                // 現在時刻を設定
			UpdatedAt:      time.Now(),                // 現在時刻を設定
		}
		if point, ok := recipeData["point"].(string); ok {
			recipe.Point = point
		}
		if pictureURL, ok := recipeData["picture_url"].(string); ok {
			recipe.PictureURL = pictureURL
		}
		if servingCount, ok := recipeData["serving_count"].(float64); ok {
			recipe.ServingCount = int(servingCount)
		}
		recipes = append(recipes, recipe)
	}
	return recipes, nil
}

func (r *SupabaseRepository) GetWeeklyRecipes(date string) ([]models.Recipe, error) {
	// 週間レシピの実装（日付フィルタリング）
	return r.GetPopularRecipes()
}

func (r *SupabaseRepository) GetUserRecipes(userID string) ([]models.Recipe, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes?user_id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var recipes []models.Recipe
	for _, recipeData := range results {
		recipe := models.Recipe{
			RecipeID:   recipeData["id"].(string),
			UserID:     recipeData["user_id"].(string),
			CategoryID: recipeData["category_id"].(string),
			Title:      recipeData["title"].(string),
			Status:     recipeData["status"].(string),
		}
		if point, ok := recipeData["point"].(string); ok {
			recipe.Point = point
		}
		if pictureURL, ok := recipeData["picture_url"].(string); ok {
			recipe.PictureURL = pictureURL
		}
		if servingCount, ok := recipeData["serving_count"].(float64); ok {
			recipe.ServingCount = int(servingCount)
		}
		recipes = append(recipes, recipe)
	}
	return recipes, nil
}

func (r *SupabaseRepository) GetFavoriteRecipes(userID string) ([]models.Recipe, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/favorite_recipes?user_id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var recipes []models.Recipe
	for _, favData := range results {
		recipeID := favData["recipe_id"].(string)
		recipe, err := r.GetRecipe(recipeID)
		if err == nil {
			recipes = append(recipes, *recipe)
		}
	}
	return recipes, nil
}

func (r *SupabaseRepository) AddFavoriteRecipe(userID, recipeID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/favorite_recipes", r.baseURL)
	data := map[string]interface{}{
		"user_id":   userID,
		"recipe_id": recipeID,
	}
	_, err := r.makeRequest("POST", endpoint, data)
	return err
}

func (r *SupabaseRepository) RemoveFavoriteRecipe(userID, recipeID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/favorite_recipes?user_id=eq.%s&recipe_id=eq.%s", r.baseURL, userID, recipeID)
	_, err := r.makeRequest("DELETE", endpoint, nil)
	return err
}

// カテゴリ関連
func (r *SupabaseRepository) GetCategories() ([]models.Category, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/categories", r.baseURL)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var categories []models.Category
	for _, catData := range results {
		category := models.Category{
			Value: catData["value"].(string),
		}
		categories = append(categories, category)
	}
	return categories, nil
}

// コメント関連
func (r *SupabaseRepository) CreateComment(comment models.Comment) (*models.Comment, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/comments", r.baseURL)
	results, err := r.makeRequest("POST", endpoint, comment)
	if err != nil {
		return nil, err
	}
	if len(results) > 0 {
		commentData := results[0]
		comment.CommentID = commentData["id"].(string)
		comment.UserID = commentData["user_id"].(string)
		comment.RecipeID = commentData["recipe_id"].(string)
		comment.Content = commentData["content"].(string)
		return &comment, nil
	}
	return nil, fmt.Errorf("no result returned")
}

func (r *SupabaseRepository) UpdateComment(commentID string, updates map[string]interface{}) error {
	endpoint := fmt.Sprintf("%s/rest/v1/comments?id=eq.%s", r.baseURL, commentID)
	_, err := r.makeRequest("PATCH", endpoint, updates)
	return err
}

func (r *SupabaseRepository) DeleteComment(commentID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/comments?id=eq.%s", r.baseURL, commentID)
	_, err := r.makeRequest("DELETE", endpoint, nil)
	return err
}

// フォロー関連
func (r *SupabaseRepository) FollowUser(userID, followerID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/follows", r.baseURL)
	data := map[string]interface{}{
		"user_id":     userID,
		"follower_id": followerID,
	}
	_, err := r.makeRequest("POST", endpoint, data)
	return err
}

func (r *SupabaseRepository) UnfollowUser(userID, followerID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/follows?user_id=eq.%s&follower_id=eq.%s", r.baseURL, userID, followerID)
	_, err := r.makeRequest("DELETE", endpoint, nil)
	return err
}

func (r *SupabaseRepository) GetFollowers(userID string) ([]string, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/follows?user_id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var followers []string
	for _, followData := range results {
		followers = append(followers, followData["follower_id"].(string))
	}
	return followers, nil
}

// ブロック関連
func (r *SupabaseRepository) BlockUser(userID, blockerID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/blocks", r.baseURL)
	data := map[string]interface{}{
		"user_id":    userID,
		"blocker_id": blockerID,
	}
	_, err := r.makeRequest("POST", endpoint, data)
	return err
}

func (r *SupabaseRepository) UnblockUser(userID, blockerID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/blocks?user_id=eq.%s&blocker_id=eq.%s", r.baseURL, userID, blockerID)
	_, err := r.makeRequest("DELETE", endpoint, nil)
	return err
}

func (r *SupabaseRepository) GetBlocks(userID string) ([]string, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/blocks?user_id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var blockers []string
	for _, blockData := range results {
		blockers = append(blockers, blockData["blocker_id"].(string))
	}
	return blockers, nil
}

// 通知関連
func (r *SupabaseRepository) GetNotices(userID string) ([]models.Notice, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/notices?user_id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var notices []models.Notice
	for _, noticeData := range results {
		notice := models.Notice{
			Title:   noticeData["title"].(string),
			Content: noticeData["content"].(string),
		}
		notices = append(notices, notice)
	}
	return notices, nil
}

func (r *SupabaseRepository) UpdateNoticeStatus(userID string, noticeID string) error {
	endpoint := fmt.Sprintf("%s/rest/v1/notices?id=eq.%s&user_id=eq.%s", r.baseURL, noticeID, userID)
	updates := map[string]interface{}{"is_read": true}
	_, err := r.makeRequest("PATCH", endpoint, updates)
	return err
}

// 設定関連
func (r *SupabaseRepository) UpdateWinkSetting(userID string, isWink bool) error {
	return r.UpdateUser(userID, map[string]interface{}{"is_wink": isWink})
}

func (r *SupabaseRepository) UpdateAISetting(userID string, isAI bool) error {
	return r.UpdateUser(userID, map[string]interface{}{"is_ai": isAI})
}

func (r *SupabaseRepository) UpdateLocationSetting(userID string, location string) error {
	return r.UpdateUser(userID, map[string]interface{}{"location": location})
}

// 検索関連
func (r *SupabaseRepository) GetSearchHistory(userID string) ([]string, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/search_histories?user_id=eq.%s", r.baseURL, userID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var words []string
	for _, historyData := range results {
		words = append(words, historyData["word"].(string))
	}
	return words, nil
}

func (r *SupabaseRepository) SearchByWord(word string) ([]models.RecipeSummary, error) {
	// まず、すべてのレシピを取得してからGoでフィルタリング
	endpoint := fmt.Sprintf("%s/rest/v1/recipes", r.baseURL)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var recipes []models.RecipeSummary
	for _, result := range results {
		// タイトルで検索
		title := result["title"].(string)
		if strings.Contains(title, word) {
			recipes = append(recipes, models.RecipeSummary{
				RecipeID:     result["id"].(string),
				UserID:       result["user_id"].(string),
				CategoryID:   result["category_id"].(string),
				Status:       result["status"].(string),
				Title:        title,
				PictureURL:   result["picture_url"].(string),
				ServingCount: int(result["serving_count"].(float64)),
			})
			continue
		}

		// 材料名で検索（材料テーブルから該当するrecipe_idを取得）
		recipeID := result["id"].(string)
		materialEndpoint := fmt.Sprintf("%s/rest/v1/recipe_materials?recipe_id=eq.%s", r.baseURL, recipeID)
		materialResults, err := r.makeRequest("GET", materialEndpoint, nil)
		if err != nil {
			continue // 材料取得でエラーが発生しても続行
		}

		// 材料名に検索語が含まれているかチェック
		for _, materialResult := range materialResults {
			materialName := materialResult["material_name"].(string)
			if strings.Contains(materialName, word) {
				recipes = append(recipes, models.RecipeSummary{
					RecipeID:     recipeID,
					UserID:       result["user_id"].(string),
					CategoryID:   result["category_id"].(string),
					Status:       result["status"].(string),
					Title:        title,
					PictureURL:   result["picture_url"].(string),
					ServingCount: int(result["serving_count"].(float64)),
				})
				break // 1つの材料でマッチしたら十分
			}
		}
	}

	return recipes, nil
}

func (r *SupabaseRepository) SearchByCategory(categoryID string) ([]models.Recipe, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes?category_id=eq.%s", r.baseURL, categoryID)
	results, err := r.makeRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}

	var recipes []models.Recipe
	for _, recipeData := range results {
		recipe := models.Recipe{
			RecipeID:   recipeData["id"].(string),
			UserID:     recipeData["user_id"].(string),
			CategoryID: recipeData["category_id"].(string),
			Title:      recipeData["title"].(string),
			Status:     recipeData["status"].(string),
		}
		if point, ok := recipeData["point"].(string); ok {
			recipe.Point = point
		}
		if pictureURL, ok := recipeData["picture_url"].(string); ok {
			recipe.PictureURL = pictureURL
		}
		if servingCount, ok := recipeData["serving_count"].(float64); ok {
			recipe.ServingCount = int(servingCount)
		}
		recipes = append(recipes, recipe)
	}
	return recipes, nil
}
