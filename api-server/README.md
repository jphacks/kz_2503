# API Server

レシピアプリケーションのバックエンドAPIサーバーです。Go言語で実装されており、現在はモックデータを使用しています。

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

## 起動方法

1. 依存関係をインストール
```bash
go mod tidy
```

2. サーバーを起動
```bash
go run main.go
```

または

```bash
go build -o server main.go
./server
```

サーバーは `http://localhost:8080` で起動します。

## テスト

### レシピ取得の例
```bash
curl -X GET http://localhost:8080/recipe/123
```

### ユーザー取得の例
```bash
curl -X GET http://localhost:8080/user/123
```

### レシピ作成の例
```bash
curl -X POST http://localhost:8080/recipe \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "123",
    "category_id": "123",
    "status": "open",
    "title": "テストレシピ",
    "picture_url": "https://example.com/image.jpg",
    "point": "テストポイント",
    "serving_count": 4,
    "recipe_material": [
      {
        "material_name": "テスト材料",
        "material_count": "1",
        "material_unit": "個"
      }
    ],
    "recipe_content": [
      {
        "picture_url": "https://example.com/step1.jpg",
        "step": 1,
        "description": "テスト手順"
      }
    ]
  }'
```

## プロジェクト構造

```
api-server/
├── main.go              # メインエントリーポイント
├── models/
│   └── models.go        # データモデル定義
├── handlers/
│   ├── recipe.go        # レシピ関連ハンドラー
│   └── user.go          # ユーザー関連ハンドラー
├── go.mod               # Go依存関係管理
└── README.md            # このファイル
```

## 注意事項

- 現在はモックデータを使用しており、データベース接続はありません
- サーバーを再起動すると、データは初期状態に戻ります
- CORS設定により、フロントエンドからのアクセスが可能です
