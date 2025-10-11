/block/{user_id}
POST

# Body

```json
{
	"blocker_id" : "123"
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "ブロックしました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/block/{user_id}
DELETE

# Body

```json
{
	"blocker_id" : "123"
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "ブロックを解除しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/block/{user_id}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"block" : [
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