-- ステップ4: サンプルデータの挿入

-- カテゴリデータ
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
