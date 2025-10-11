package config

import (
	"log"
	"os"

	"github.com/supabase-community/supabase-go"
)

var SupabaseClient *supabase.Client

// InitSupabase Supabaseクライアントを初期化
func InitSupabase() {
	url := os.Getenv("SUPABASE_URL")
	anonKey := os.Getenv("SUPABASE_ANON_KEY")

	if url == "" || anonKey == "" {
		log.Fatal("Supabase URL and Anon Key must be set in environment variables")
	}

	client, err := supabase.NewClient(url, anonKey, nil)
	if err != nil {
		log.Fatal("Failed to create Supabase client:", err)
	}

	SupabaseClient = client
	log.Println("Supabase client initialized successfully")
}
