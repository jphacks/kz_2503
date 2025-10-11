/notice/{user_id}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,	
	"notice" : [
		{
			"title" : "フォロー通知",
			"content" : "なぎささんからフォローされました",
		}
	]
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/notice/{user_id}
PATCH

# Body

```json
{
	"user_id" : "123"
	"status" : "already read"
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "更新完了しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```