/settings/wink/{user_id}
PATCH

# Body

```json
{
	"is_wink" : true,
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "ウィンクスイッチを ON にしました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/settings/ai/{user_id}
PATCH

# Body

```json
{
	"is_ai" : true,
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "AI モードを ON にしました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/settings/location/{user_id}
PATCH

# Body

```json
{
	"location" : "Japan",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "地域を Japan にしました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```