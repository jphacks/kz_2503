//
//  SearchView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("SearchView")
                .font(.largeTitle)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Text("ここに検索機能を実装します")
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .background(Color.white)
        .navigationTitle("検索")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}