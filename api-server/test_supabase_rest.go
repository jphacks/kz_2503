package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

func main() {
	// 環境変数を読み込み
	if err := godotenv.Load("config.env"); err != nil {
		log.Println("No config.env file found, using system environment variables")
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	apiKey := os.Getenv("SUPABASE_ANON_KEY")

	if supabaseURL == "" || apiKey == "" {
		log.Fatal("SUPABASE_URL and SUPABASE_ANON_KEY must be set")
	}

	log.Printf("Supabase URL: %s", supabaseURL)
	log.Printf("API Key: %s...", apiKey[:10])

	// 1. カテゴリ一覧を取得
	log.Println("\n=== カテゴリ一覧取得テスト ===")
	categories, err := getCategories(supabaseURL, apiKey)
	if err != nil {
		log.Printf("カテゴリ取得エラー: %v", err)
	} else {
		log.Printf("カテゴリ数: %d", len(categories))
		for _, cat := range categories {
			log.Printf("カテゴリ: %v", cat)
		}
	}

	// 2. ユーザー一覧を取得
	log.Println("\n=== ユーザー一覧取得テスト ===")
	users, err := getUsers(supabaseURL, apiKey)
	if err != nil {
		log.Printf("ユーザー取得エラー: %v", err)
	} else {
		log.Printf("ユーザー数: %d", len(users))
		for _, user := range users {
			log.Printf("ユーザー: %v", user)
		}
	}

	// 3. レシピ一覧を取得
	log.Println("\n=== レシピ一覧取得テスト ===")
	recipes, err := getRecipes(supabaseURL, apiKey)
	if err != nil {
		log.Printf("レシピ取得エラー: %v", err)
	} else {
		log.Printf("レシピ数: %d", len(recipes))
		for _, recipe := range recipes {
			log.Printf("レシピ: %v", recipe)
		}
	}

	// 4. 新しいレシピを追加
	log.Println("\n=== レシピ追加テスト ===")
	newRecipe := map[string]interface{}{
		"title":         "テストレシピ",
		"point":         "これはテスト用のレシピです",
		"serving_count": 2,
		"status":        "open",
		"user_id":       "123e4567-e89b-12d3-a456-426614174000", // 既存のユーザーID
		"category_id":   "",                                     // カテゴリIDを取得して設定
	}

	// カテゴリIDを取得
	if len(categories) > 0 {
		if catID, ok := categories[0]["id"].(string); ok {
			newRecipe["category_id"] = catID
		}
	}

	addedRecipe, err := addRecipe(supabaseURL, apiKey, newRecipe)
	if err != nil {
		log.Printf("レシピ追加エラー: %v", err)
	} else {
		log.Printf("レシピ追加成功: %v", addedRecipe)
	}
}

func getCategories(url, apiKey string) ([]map[string]interface{}, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/categories", url)
	return makeRequest("GET", endpoint, apiKey, nil)
}

func getUsers(url, apiKey string) ([]map[string]interface{}, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/users", url)
	return makeRequest("GET", endpoint, apiKey, nil)
}

func getRecipes(url, apiKey string) ([]map[string]interface{}, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes", url)
	return makeRequest("GET", endpoint, apiKey, nil)
}

func addRecipe(url, apiKey string, recipe map[string]interface{}) (map[string]interface{}, error) {
	endpoint := fmt.Sprintf("%s/rest/v1/recipes", url)

	// POSTリクエスト用の特別な処理
	jsonData, err := json.Marshal(recipe)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", endpoint, strings.NewReader(string(jsonData)))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", apiKey)
	req.Header.Set("Authorization", "Bearer "+apiKey)
	req.Header.Set("Prefer", "return=representation") // 作成されたレコードを返すように指定

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

	log.Printf("レスポンスステータス: %d", resp.StatusCode)
	log.Printf("レスポンスボディ: %s", string(respBody))

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(respBody))
	}

	var result []map[string]interface{}
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("JSON parse error: %v, body: %s", err, string(respBody))
	}

	if len(result) > 0 {
		return result[0], nil
	}
	return nil, fmt.Errorf("no result returned")
}

func makeRequest(method, endpoint, apiKey string, body interface{}) ([]map[string]interface{}, error) {
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
	req.Header.Set("apikey", apiKey)
	req.Header.Set("Authorization", "Bearer "+apiKey)

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
	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, err
	}

	return result, nil
}
