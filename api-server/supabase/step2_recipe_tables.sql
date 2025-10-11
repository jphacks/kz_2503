-- ステップ2: レシピ関連テーブル

-- レシピテーブル
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'open',
    title VARCHAR(200) NOT NULL,
    picture_url VARCHAR(500),
    point TEXT,
    serving_count INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- レシピ材料テーブル
CREATE TABLE recipe_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    material_name VARCHAR(100) NOT NULL,
    material_count VARCHAR(50) NOT NULL,
    material_unit VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- レシピ手順テーブル
CREATE TABLE recipe_contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    picture_url VARCHAR(500),
    step INTEGER NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
