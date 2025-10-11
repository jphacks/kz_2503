-- 簡単なテーブル作成用SQL（SupabaseのSQL Editorで実行）

-- 1. カテゴリテーブル
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    value VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. ユーザーテーブル
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

-- 3. レシピテーブル
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
