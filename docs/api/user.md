/user
POST

# Body

```json
{
	"username" : "kota",
	"password_hash" : "123",
	"mailadress" : "akokoa1221@gmail.com",
	"location" : "Japan",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"user_id" : "123"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/user/{email}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"user_id" : "123",
}
```

## 202

```json
{
	"status" : 202,
	"message" : "アカウントが存在しません",
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/user/{user_id}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"username" : "123",
	"mailadress" : "akokoa1221@gmail.com",
	"profile" : "金沢の主婦です",
	"icon" : "https://imgur.com/a/dsfJeyk",
	"is_wink" : true,
	"location" : "Japan",
	"is_ai" : true,
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/user/{user_id}
DELETE

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "ユーザーを削除しました",
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました",
}
```



/user/login/
POST

# Body

```json
{
	"user_id" : "123",
	"password_hash" : "123",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "ログイン完了しました",
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました",
}
```



/user/profile/{user_id}
PATCH

# Body

```json
{
	"user_id" : "123",
	"profile" : "金沢の主婦です。",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "プロフィールを更新しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/user/password/{user_id}
PATCH

# Body

```json
{
	"user_id" : "123",
	"password_hash" : "123",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "パスワードを更新しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/user/icon/{user_id}
PATCH

# Body

```json
{
	"user_id" : "123",
	"Icon" : "https://imgur.com/a/dsfJeyk",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "アイコンを更新しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```