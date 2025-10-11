//
//  BottomNavigationView.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import SwiftUI

struct BottomNavigationView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: CaseIterable {
        case home
        case record
        case menu
        
        var title: String {
            switch self {
            case .home:
                return "ホーム"
            case .record:
                return "きろく"
            case .menu:
                return "献立"
            }
        }
        
        var icon: String {
            switch self {
            case .home:
                return "house"
            case .record:
                return "doc.text"
            case .menu:
                return "fork.knife"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == tab ? .black : .gray)
                        
                        Text(tab.title)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .black : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
    }
}

#Preview {
    BottomNavigationView()
}

