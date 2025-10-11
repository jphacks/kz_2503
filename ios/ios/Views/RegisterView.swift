//
//  RegisterView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct RegisterView: View {
    let email: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("新規登録画面")
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Text("メールアドレス: \(email)")
                .font(.body)
                .foregroundColor(.gray)
            
            Text("ここに新規登録機能を実装します")
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .background(Color.white)
        .navigationTitle("新規登録")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RegisterView(email: "user@example.com")
    }
}
