//
//  RecipeCardView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct RecipeCardView: View {
    let title: String
    let ingredients: [String]
    let chefName: String
    let imageUrl: String?
    let userIconUrl: String?
    
    init(title: String, ingredients: [String], chefName: String, imageUrl: String? = nil, userIconUrl: String? = nil) {
        self.title = title
        self.ingredients = ingredients
        self.chefName = chefName
        self.imageUrl = imageUrl
        self.userIconUrl = userIconUrl
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 左側: コンテンツ
            VStack(alignment: .leading, spacing: 8) {
                // 料理名
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                // 材料
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(ingredients.prefix(3), id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if ingredients.count > 3 {
                        Text("...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // ユーザー情報
                HStack(spacing: 8) {
                    // ユーザーアイコン
                    if let userIconUrl = userIconUrl, !userIconUrl.isEmpty {
                        AsyncImage(url: URL(string: userIconUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                    }
                    
                    Text(chefName)
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右側: 画像
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if let imageUrl = imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_):
                            Image(systemName: "photo")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 24))
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        @unknown default:
                            Image(systemName: "photo")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 24))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 24))
                }
                
                // ハートアイコン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // TODO: お気に入り機能
                        }) {
                            Image(systemName: "heart")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                )
                        }
                        .padding(4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    RecipeCardView(
        title: "カレーライス",
        ingredients: ["玉ねぎ", "にんじん", "じゃがいも", "カレールー"],
        chefName: "kota"
    )
    .padding()
}
