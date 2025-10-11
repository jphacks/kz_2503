package repositories

import (
	"api-server/interfaces"
	"api-server/models"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"
)

type MockRepository struct {
	data *models.MockData
}

func NewMockRepository() interfaces.Repository {
	return &MockRepository{
		data: models.MockDB,
	}
}

// ユーザー関連
func (r *MockRepository) CreateUser(user models.User) (*models.User, error) {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	// 新しいユーザーIDを生成
	userID := strconv.FormatInt(time.Now().UnixNano(), 10)
	user.UserID = userID
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	r.data.Users[userID] = user
	return &user, nil
}

func (r *MockRepository) GetUser(userID string) (*models.User, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	user, exists := r.data.Users[userID]
	if !exists {
		return nil, fmt.Errorf("user not found")
	}
	return &user, nil
}

func (r *MockRepository) GetUserByEmail(email string) (*models.User, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	for _, user := range r.data.Users {
		if user.MailAddress == email {
			return &user, nil
		}
	}
	return nil, fmt.Errorf("user not found")
}

func (r *MockRepository) UpdateUser(userID string, updates map[string]interface{}) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	user, exists := r.data.Users[userID]
	if !exists {
		return fmt.Errorf("user not found")
	}

	// 更新処理
	if username, ok := updates["username"].(string); ok {
		user.Username = username
	}
	if email, ok := updates["mail_address"].(string); ok {
		user.MailAddress = email
	}
	if profile, ok := updates["profile"].(string); ok {
		user.Profile = profile
	}
	if icon, ok := updates["icon"].(string); ok {
		user.Icon = icon
	}
	if isWink, ok := updates["is_wink"].(bool); ok {
		user.IsWink = isWink
	}
	if location, ok := updates["location"].(string); ok {
		user.Location = location
	}
	if isAI, ok := updates["is_ai"].(bool); ok {
		user.IsAI = isAI
	}

	user.UpdatedAt = time.Now()
	r.data.Users[userID] = user
	return nil
}

func (r *MockRepository) DeleteUser(userID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	delete(r.data.Users, userID)
	return nil
}

func (r *MockRepository) LoginUser(userID, passwordHash string) (*models.User, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	user, exists := r.data.Users[userID]
	if !exists || user.PasswordHash != passwordHash {
		return nil, fmt.Errorf("invalid credentials")
	}
	return &user, nil
}

// レシピ関連
func (r *MockRepository) CreateRecipe(recipe models.Recipe) (*models.Recipe, error) {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	recipeID := strconv.FormatInt(time.Now().UnixNano(), 10)
	recipe.RecipeID = recipeID
	recipe.CreatedAt = time.Now()
	recipe.UpdatedAt = time.Now()

	r.data.Recipes[recipeID] = recipe
	return &recipe, nil
}

func (r *MockRepository) GetRecipe(recipeID string) (*models.Recipe, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	recipe, exists := r.data.Recipes[recipeID]
	if !exists {
		return nil, fmt.Errorf("recipe not found")
	}
	return &recipe, nil
}

func (r *MockRepository) UpdateRecipe(recipeID string, updates map[string]interface{}) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	recipe, exists := r.data.Recipes[recipeID]
	if !exists {
		return fmt.Errorf("recipe not found")
	}

	// 更新処理
	if title, ok := updates["title"].(string); ok {
		recipe.Title = title
	}
	if point, ok := updates["point"].(string); ok {
		recipe.Point = point
	}
	if pictureURL, ok := updates["picture_url"].(string); ok {
		recipe.PictureURL = pictureURL
	}
	if servingCount, ok := updates["serving_count"].(int); ok {
		recipe.ServingCount = servingCount
	}
	if status, ok := updates["status"].(string); ok {
		recipe.Status = status
	}

	recipe.UpdatedAt = time.Now()
	r.data.Recipes[recipeID] = recipe
	return nil
}

func (r *MockRepository) DeleteRecipe(recipeID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	delete(r.data.Recipes, recipeID)
	return nil
}

func (r *MockRepository) GetPopularRecipes() ([]models.Recipe, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	var recipes []models.Recipe
	for _, recipe := range r.data.Recipes {
		recipes = append(recipes, recipe)
	}

	// serving_countで降順ソート
	sort.Slice(recipes, func(i, j int) bool {
		return recipes[i].ServingCount > recipes[j].ServingCount
	})

	return recipes, nil
}

func (r *MockRepository) GetWeeklyRecipes(date string) ([]models.Recipe, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	var recipes []models.Recipe
	for _, recipe := range r.data.Recipes {
		recipes = append(recipes, recipe)
	}
	return recipes, nil
}

func (r *MockRepository) GetUserRecipes(userID string) ([]models.Recipe, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	var recipes []models.Recipe
	for _, recipe := range r.data.Recipes {
		if recipe.UserID == userID {
			recipes = append(recipes, recipe)
		}
	}
	return recipes, nil
}

func (r *MockRepository) GetFavoriteRecipes(userID string) ([]models.Recipe, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	var recipes []models.Recipe
	favoriteIDs, exists := r.data.FavoriteRecipes[userID]
	if !exists {
		return recipes, nil
	}

	for _, recipeID := range favoriteIDs {
		if recipe, exists := r.data.Recipes[recipeID]; exists {
			recipes = append(recipes, recipe)
		}
	}
	return recipes, nil
}

func (r *MockRepository) AddFavoriteRecipe(userID, recipeID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	// 既に存在するかチェック
	for _, id := range r.data.FavoriteRecipes[userID] {
		if id == recipeID {
			return nil // 既に存在
		}
	}

	r.data.FavoriteRecipes[userID] = append(r.data.FavoriteRecipes[userID], recipeID)
	return nil
}

func (r *MockRepository) RemoveFavoriteRecipe(userID, recipeID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	favorites := r.data.FavoriteRecipes[userID]
	for i, id := range favorites {
		if id == recipeID {
			r.data.FavoriteRecipes[userID] = append(favorites[:i], favorites[i+1:]...)
			break
		}
	}
	return nil
}

// カテゴリ関連
func (r *MockRepository) GetCategories() ([]models.Category, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	return r.data.Categories, nil
}

// コメント関連
func (r *MockRepository) CreateComment(comment models.Comment) (*models.Comment, error) {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	commentID := strconv.FormatInt(time.Now().UnixNano(), 10)
	comment.CommentID = commentID

	r.data.Comments[commentID] = comment
	return &comment, nil
}

func (r *MockRepository) UpdateComment(commentID string, updates map[string]interface{}) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	comment, exists := r.data.Comments[commentID]
	if !exists {
		return fmt.Errorf("comment not found")
	}

	if content, ok := updates["content"].(string); ok {
		comment.Content = content
	}

	r.data.Comments[commentID] = comment
	return nil
}

func (r *MockRepository) DeleteComment(commentID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	delete(r.data.Comments, commentID)
	return nil
}

// フォロー関連
func (r *MockRepository) FollowUser(userID, followerID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	// 既にフォローしているかチェック
	for _, id := range r.data.Follows[userID] {
		if id == followerID {
			return nil // 既にフォロー済み
		}
	}

	r.data.Follows[userID] = append(r.data.Follows[userID], followerID)
	return nil
}

func (r *MockRepository) UnfollowUser(userID, followerID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	followers := r.data.Follows[userID]
	for i, id := range followers {
		if id == followerID {
			r.data.Follows[userID] = append(followers[:i], followers[i+1:]...)
			break
		}
	}
	return nil
}

func (r *MockRepository) GetFollowers(userID string) ([]string, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	return r.data.Follows[userID], nil
}

// ブロック関連
func (r *MockRepository) BlockUser(userID, blockerID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	// 既にブロックしているかチェック
	for _, id := range r.data.Blocks[userID] {
		if id == blockerID {
			return nil // 既にブロック済み
		}
	}

	r.data.Blocks[userID] = append(r.data.Blocks[userID], blockerID)
	return nil
}

func (r *MockRepository) UnblockUser(userID, blockerID string) error {
	r.data.Mu.Lock()
	defer r.data.Mu.Unlock()

	blocks := r.data.Blocks[userID]
	for i, id := range blocks {
		if id == blockerID {
			r.data.Blocks[userID] = append(blocks[:i], blocks[i+1:]...)
			break
		}
	}
	return nil
}

func (r *MockRepository) GetBlocks(userID string) ([]string, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	return r.data.Blocks[userID], nil
}

// 通知関連
func (r *MockRepository) GetNotices(userID string) ([]models.Notice, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	return r.data.Notices[userID], nil
}

func (r *MockRepository) UpdateNoticeStatus(userID string, noticeID string) error {
	// モックでは何もしない
	return nil
}

// 設定関連
func (r *MockRepository) UpdateWinkSetting(userID string, isWink bool) error {
	return r.UpdateUser(userID, map[string]interface{}{"is_wink": isWink})
}

func (r *MockRepository) UpdateAISetting(userID string, isAI bool) error {
	return r.UpdateUser(userID, map[string]interface{}{"is_ai": isAI})
}

func (r *MockRepository) UpdateLocationSetting(userID string, location string) error {
	return r.UpdateUser(userID, map[string]interface{}{"location": location})
}

// 検索関連
func (r *MockRepository) GetSearchHistory(userID string) ([]string, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	return r.data.SearchHistory[userID], nil
}

func (r *MockRepository) SearchByWord(word string) ([]models.RecipeSummary, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	var recipes []models.RecipeSummary
	for _, recipe := range r.data.Recipes {
		// タイトルで検索
		if strings.Contains(recipe.Title, word) {
			recipes = append(recipes, models.RecipeSummary{
				RecipeID:     recipe.RecipeID,
				UserID:       recipe.UserID,
				CategoryID:   recipe.CategoryID,
				Status:       recipe.Status,
				Title:        recipe.Title,
				PictureURL:   recipe.PictureURL,
				ServingCount: recipe.ServingCount,
			})
			continue
		}

		// 材料名で検索
		for _, material := range recipe.RecipeMaterial {
			if strings.Contains(material.MaterialName, word) {
				recipes = append(recipes, models.RecipeSummary{
					RecipeID:     recipe.RecipeID,
					UserID:       recipe.UserID,
					CategoryID:   recipe.CategoryID,
					Status:       recipe.Status,
					Title:        recipe.Title,
					PictureURL:   recipe.PictureURL,
					ServingCount: recipe.ServingCount,
				})
				break
			}
		}
	}
	return recipes, nil
}

func (r *MockRepository) SearchByCategory(categoryID string) ([]models.Recipe, error) {
	r.data.Mu.RLock()
	defer r.data.Mu.RUnlock()

	var recipes []models.Recipe
	for _, recipe := range r.data.Recipes {
		if recipe.CategoryID == categoryID {
			recipes = append(recipes, recipe)
		}
	}
	return recipes, nil
}
