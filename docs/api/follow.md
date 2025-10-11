/follow/{user_id}
POST

# Body

```json
{
	"follower_id" : "123"
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "フォローしました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/follow/{user_id}
DELETE

# Body

```json
{
	"follower_id" : "123"
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "フォローを解除しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/follow/{user_id}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"follower" : [
		{
			"user_id" : "123",
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