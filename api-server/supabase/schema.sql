-- レシピアプリケーション用のSupabaseスキーマ

-- ユーザーテーブル
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    mail_address VARCHAR(255) UNIQUE NOT NULL,
    profile TEXT,
    icon VARCHAR(500),
    is_wink BOOLEAN DEFAULT false,
    location VARCHAR(100),
    is_ai BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- カテゴリテーブル
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    value VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- レシピテーブル
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'private', 'draft')),
    title VARCHAR(200) NOT NULL,
    picture_url VARCHAR(500),
    point TEXT,
    serving_count INTEGER DEFAULT 1 CHECK (serving_count > 0),
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
    step INTEGER NOT NULL CHECK (step > 0),
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- コメントテーブル
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- お気に入りレシピテーブル
CREATE TABLE favorite_recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

-- フォローテーブル
CREATE TABLE follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, follower_id),
    CHECK(user_id != follower_id)
);

-- ブロックテーブル
CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, blocker_id),
    CHECK(user_id != blocker_id)
);

-- 通知テーブル
CREATE TABLE notices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 検索履歴テーブル
CREATE TABLE search_histories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    word VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- インデックス作成
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_recipes_category_id ON recipes(category_id);
CREATE INDEX idx_recipes_created_at ON recipes(created_at);
CREATE INDEX idx_recipe_materials_recipe_id ON recipe_materials(recipe_id);
CREATE INDEX idx_recipe_contents_recipe_id ON recipe_contents(recipe_id);
CREATE INDEX idx_comments_recipe_id ON comments(recipe_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_favorite_recipes_user_id ON favorite_recipes(user_id);
CREATE INDEX idx_follows_user_id ON follows(user_id);
CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_blocks_user_id ON blocks(user_id);
CREATE INDEX idx_blocks_blocker_id ON blocks(blocker_id);
CREATE INDEX idx_notices_user_id ON notices(user_id);
CREATE INDEX idx_notices_is_read ON notices(is_read);
CREATE INDEX idx_search_histories_user_id ON search_histories(user_id);

-- 更新日時を自動更新するトリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- トリガー設定
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- サンプルデータの挿入
INSERT INTO categories (value) VALUES 
('サラダ'),
('スープ'),
('メイン'),
('デザート'),
('飲み物');

-- サンプルユーザー
INSERT INTO users (id, username, password_hash, mail_address, profile, icon, is_wink, location, is_ai) VALUES 
('123e4567-e89b-12d3-a456-426614174000', 'kota', '123', 'akokoa1221@gmail.com', '金沢の主婦です', 'https://imgur.com/a/dsfJeyk', true, 'Japan', true);

-- サンプルレシピ
INSERT INTO recipes (id, user_id, category_id, status, title, picture_url, point, serving_count) VALUES 
('123e4567-e89b-12d3-a456-426614174001', '123e4567-e89b-12d3-a456-426614174000', (SELECT id FROM categories WHERE value = 'メイン'), 'open', 'カレー', 'https://imgur.com/a/dsfJeyk', 'こんにゃくを入れます', 2);

-- サンプルレシピ材料
INSERT INTO recipe_materials (recipe_id, material_name, material_count, material_unit) VALUES 
('123e4567-e89b-12d3-a456-426614174001', '人参', '2', '本');

-- サンプルレシピ手順
INSERT INTO recipe_contents (recipe_id, picture_url, step, description) VALUES 
('123e4567-e89b-12d3-a456-426614174001', 'https://imgur.com/a/dsfJeyk', 1, '人参を切ります');

-- サンプルお気に入り
INSERT INTO favorite_recipes (user_id, recipe_id) VALUES 
('123e4567-e89b-12d3-a456-426614174000', '123e4567-e89b-12d3-a456-426614174001');

-- サンプルコメント
INSERT INTO comments (user_id, recipe_id, content) VALUES 
('123e4567-e89b-12d3-a456-426614174000', '123e4567-e89b-12d3-a456-426614174001', 'とても美味しかったです！');

-- サンプル通知
INSERT INTO notices (user_id, title, content) VALUES 
('123e4567-e89b-12d3-a456-426614174000', 'フォロー通知', 'なぎささんからフォローされました');

-- サンプル検索履歴
INSERT INTO search_histories (user_id, word) VALUES 
('123e4567-e89b-12d3-a456-426614174000', 'とうもろこし'),
('123e4567-e89b-12d3-a456-426614174000', 'カレー'),
('123e4567-e89b-12d3-a456-426614174000', 'サラダ');
