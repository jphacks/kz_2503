# API Server with Dependency Injection

依存性注入を使用したAPIサーバーです。モックとSupabaseを簡単に切り替えることができます。

## 🚀 起動方法

### 方法1: スクリプトを使用（推奨）

**モック版を起動:**
```bash
./run_mock.sh
```

**Supabase版を起動:**
```bash
./run_supabase.sh
```

### 方法2: 環境変数を使用

**モック版を起動:**
```bash
./server_di
# または
REPOSITORY_TYPE=mock ./server_di
```

**Supabase版を起動:**
```bash
USE_SUPABASE=true ./server_di
# または
REPOSITORY_TYPE=supabase ./server_di
```

### 方法3: 設定ファイルを使用

`config.env`ファイルを作成:
```bash
cp config.env.example config.env
```

`config.env`を編集:
```env
# リポジトリ選択 (mock または supabase)
REPOSITORY_TYPE=mock

# Supabase設定（supabase使用時のみ必要）
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

## 🔧 切り替えの仕組み

### 依存性注入の設計

1. **インターフェース定義** (`interfaces/repository.go`)
   - 全リポジトリが実装すべきメソッドを定義

2. **モックリポジトリ** (`repositories/mock_repository.go`)
   - メモリ内でデータを管理
   - 開発・テスト用

3. **Supabaseリポジトリ** (`repositories/supabase_repository.go`)
   - 実際のデータベースと連携
   - 本番用

### 切り替えロジック

```go
// main_di.go
repositoryType := os.Getenv("REPOSITORY_TYPE")
useSupabase := os.Getenv("USE_SUPABASE") == "true" || repositoryType == "supabase"

if useSupabase {
    repo = repositories.NewSupabaseRepository()
} else {
    repo = repositories.NewMockRepository()
}
```

## 📊 動作確認

### モック版のテスト
```bash
./run_mock.sh
curl http://localhost:8080/category
```

### Supabase版のテスト
```bash
./run_supabase.sh
curl http://localhost:8080/category
```

## 🎯 利点

- **開発効率**: モック版で高速開発
- **テスト容易**: データベース不要でテスト可能
- **本番対応**: Supabase版で実際のデータベース使用
- **拡張性**: 新しいリポジトリを簡単に追加可能
