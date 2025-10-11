package main

import (
	"api-server/config"
	"log"

	"github.com/joho/godotenv"
)

func main() {
	// 環境変数を読み込み
	if err := godotenv.Load("config.env"); err != nil {
		log.Println("No config.env file found, using system environment variables")
	}

	// Supabaseクライアントを初期化
	config.InitSupabase()

	// 簡単なテストクエリを実行
	var result []map[string]interface{}
	_, _, err := config.SupabaseClient.From("categories").Select("*", "", false).Execute(&result)
	if err != nil {
		log.Printf("Supabase接続エラー: %v", err)
		return
	}

	log.Printf("Supabase接続成功！")
	log.Printf("カテゴリ数: %d", len(result))
	for _, category := range result {
		log.Printf("カテゴリ: %v", category)
	}

	// ユーザーテーブルのテスト
	var users []map[string]interface{}
	_, _, err = config.SupabaseClient.From("users").Select("*", "", false).Execute(&users)
	if err != nil {
		log.Printf("ユーザーテーブル取得エラー: %v", err)
		return
	}

	log.Printf("ユーザー数: %d", len(users))
	for _, user := range users {
		log.Printf("ユーザー: %v", user)
	}
}
