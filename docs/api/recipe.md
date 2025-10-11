/recipe
POST

# Body

```json
{
	"user_id" : "123",
	"category_id" : "123",
	"status" : "open",
	"title" : "カレー",
	"picture_url" : "https://imgur.com/a/dsfJeyk",
	"point" : "こんにゃくを入れます",
	"serving_count" : 2,
	"recipe_material" : [
		{
			"material_name" : "人参",
			"material_count" : "2",
			"material_unit" : "本",
		}
	],
	"recipe_content" : [
		{
			"picture_url" : "https://imgur.com/a/dsfJeyk",
			"step" : 1,
			"description" : "人参を切ります",
		}
	]
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "レシピを追加しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/recipe/{recipe_id}
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
	"category_id" : "123",
	"status" : "open",
	"title" : "カレー",
	"picture_url" : "https://imgur.com/a/dsfJeyk",
	"point" : "こんにゃくを入れます",
	"serving_count" : 2,
	"recipe_material" : [
		{
			"material_name" : "人参",
			"material_count" : "2本",
		}
	],
	"recipe_content" : [
		{
			"picture_url" : "https://imgur.com/a/dsfJeyk",
			"step" : 1,
			"description" : "人参を切ります",
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



/recipe/{recipe_id}
PATCH

# Body

```json
{
	"user_id" : "123",
	"category_id" : "123",
	"status" : "open",
	"title" : "カレー",
	"picture_url" : "https://imgur.com/a/dsfJeyk",
	"point" : "こんにゃくを入れます",
	"serving_count" : 2,
	"recipe_material" : [
		{
			"material_name" : "人参",
			"material_count" : "2本",
		}
	],
	"recipe_content" : [
		{
			"picture_url" : "https://imgur.com/a/dsfJeyk",
			"step" : 1,
			"description" : "人参を切ります",
		}
	]
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "レシピを更新しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/recipe/{recipe_id}
DELETE

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "レシピを削除しました"
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/recipe/popular
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



/recipe/weekly/{date}
GET

# Body

```json

```

# Response

## 200

```json
{
	"status" : 200,
	"Sunday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
	"Monday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
	"Tuesday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
	"Wednesday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
	"Thursday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
	"Friday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
	"Saturday" : {
		"recipe_id" : "123"
		"title" : "カレー",
		"chef" : "kota",
		"picture_url" : "https://i.imgur.com/ScEqnCM.png",
	},
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/recipe/user/{user_id}
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



/recipe/favorite/{user_id}
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



/recipe/favorite/{user_id}
POST

# Body

```json
{
	"recipe_id" : "123",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "お気に入りに追加しました",
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```



/recipe/favorite/{user_id}
DELETE

# Body

```json
{
	"recipe_id" : "123",
}
```

# Response

## 200

```json
{
	"status" : 200,
	"message" : "お気に入りから削除しました",
}
```

## 400

```json
{
	"status" : 400,
	"message" : "エラーが発生しました"
}
```