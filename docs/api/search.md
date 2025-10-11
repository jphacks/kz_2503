/search/{user_id}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"word" : [
		{
			"value" : "とうもろこし"
		}
	]
}
```

## 400

```json
{
	"status" : 400,
	"error" : "エラーが発生しました"
}
```



/search/word/{word}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"recipes" : [
		{
			"recipe_id" : "123"
			"title" : "カレー",
			"chef" : "kota",
			"picture_url" : "https://i.imgur.com/ScEqnCM.png",
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



/search/category/{category_id}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"recipes" : [
		{
			"recipe_id" : "123",
			"title" : "カレー",
			"chef" : "kota",
			"picture_url" : "https://i.imgur.com/ScEqnCM.png",
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