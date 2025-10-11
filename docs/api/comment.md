/comment/{recipe_id}
POST

# Body

```json
{
	"user_id" : "123",
	"content" : "簡単だった",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "コメントしました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/comment/{recipe_id}
PATCH

# Body

```json
{
	"comment_id" : "123",
	"user_id" : "123",
	"content" : "簡単だった",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "コメントを修正しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/comment/{recipe_id}
DELETE

# Body

```json
{
	"comment_id" : "123",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "コメントを削除しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



