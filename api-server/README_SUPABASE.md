# Supabase対応API Server

レシピアプリケーションのバックエンドAPIサーバーです。Go言語で実装されており、Supabaseをデータベースとして使用します。

## セットアップ

### 1. Supabaseプロジェクトの作成

1. [Supabase](https://supabase.com)にアクセス
2. 新しいプロジェクトを作成
3. プロジェクトのURLとAPIキーを取得

### 2. データベーススキーマの設定

`supabase/schema.sql`ファイルの内容をSupabaseのSQL Editorで実行してください。

### 3. 環境変数の設定

`config.env.example`をコピーして`config.env`を作成し、Supabaseの設定を入力してください：

```bash
cp config.env.example config.env
```

`config.env`ファイルを編集：
```
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here
PORT=8080
GIN_MODE=debug
```

### 4. 依存関係のインストール

```bash
go mod tidy
```

### 5. サーバーの起動

```bash
go run main.go
```

または

```bash
go build -o server main.go
./server
```

## 機能

### レシピ関連API
- `POST /recipe` - レシピ作成
- `GET /recipe/{recipe_id}` - レシピ取得
- `PATCH /recipe/{recipe_id}` - レシピ更新
- `DELETE /recipe/{recipe_id}` - レシピ削除
- `GET /recipe/popular` - 人気レシピ取得
- `GET /recipe/weekly/{date}` - 週間レシピ取得
- `GET /recipe/user/{user_id}` - ユーザーのレシピ取得
- `GET /recipe/favorite/{user_id}` - お気に入りレシピ取得
- `POST /recipe/favorite/{user_id}` - お気に入りレシピ追加
- `DELETE /recipe/favorite/{user_id}` - お気に入りレシピ削除

### ユーザー関連API
- `POST /user` - ユーザー作成
- `GET /user/{user_id}` - ユーザー取得
- `DELETE /user/{user_id}` - ユーザー削除
- `POST /user/login` - ユーザーログイン
- `PATCH /user/profile/{user_id}` - プロフィール更新
- `PATCH /user/password/{user_id}` - パスワード更新
- `PATCH /user/icon/{user_id}` - アイコン更新

### カテゴリ関連API
- `GET /category` - カテゴリ一覧取得

### コメント関連API
- `POST /comment/{recipe_id}` - コメント作成
- `PATCH /comment/{recipe_id}` - コメント更新
- `DELETE /comment/{recipe_id}` - コメント削除

### フォロー関連API
- `POST /follow/{user_id}` - フォロー
- `DELETE /follow/{user_id}` - フォロー解除
- `GET /follow/{user_id}` - フォロワー一覧取得

### ブロック関連API
- `POST /block/{user_id}` - ブロック
- `DELETE /block/{user_id}` - ブロック解除
- `GET /block/{user_id}` - ブロック一覧取得

### 通知関連API
- `GET /notice/{user_id}` - 通知取得
- `PATCH /notice/{user_id}` - 通知既読更新

### 設定関連API
- `PATCH /settings/wink/{user_id}` - ウィンク設定更新
- `PATCH /settings/ai/{user_id}` - AI設定更新
- `PATCH /settings/location/{user_id}` - 地域設定更新

### 検索関連API
- `GET /search/{user_id}` - 検索履歴取得
- `GET /search/word/{word}` - ワード検索
- `GET /search/category/{category_id}` - カテゴリ検索

## データベーススキーマ

### テーブル一覧
- `users` - ユーザー情報
- `categories` - カテゴリ
- `recipes` - レシピ
- `recipe_materials` - レシピ材料
- `recipe_contents` - レシピ手順
- `comments` - コメント
- `favorite_recipes` - お気に入りレシピ
- `follows` - フォロー関係
- `blocks` - ブロック関係
- `notices` - 通知
- `search_histories` - 検索履歴

## 注意事項

- Supabaseの設定が正しく行われていることを確認してください
- 環境変数ファイル（`config.env`）が存在し、正しい値が設定されていることを確認してください
- データベーススキーマが正しく適用されていることを確認してください

## トラブルシューティング

### よくある問題

1. **接続エラー**: SupabaseのURLとAPIキーが正しいか確認
2. **認証エラー**: APIキーが有効か確認
3. **テーブルが見つからない**: データベーススキーマが適用されているか確認

### ログの確認

サーバーのログを確認して、エラーの詳細を把握してください。
