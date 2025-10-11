//
//  ProfileSettingViewModel.swift
//  iOS
//
//  Created by 三ツ井渚 on 2025/10/11.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileSettingViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var profileImage: String = ""
    @Published var isLoading: Bool = false
    @Published var resultMessage: String = ""
    @Published var showResult: Bool = false
    @Published var resultType: ResultType = .none
    @Published var updateSuccess: Bool = false
    @Published var navigationDestination: NavigationDestination? = nil
    
    private let profileUpdateRepository = ProfileUpdateRepository()
    private let userIdRepository = UserIdRepository()
    
    enum ResultType {
        case none
        case success
        case error
    }
    
    enum NavigationDestination: Hashable {
        case search
    }
    
    func updateProfile() async {
        // バリデーション
        guard let userId = userIdRepository.getCurrentUserId() else {
            showResult(message: "ユーザーIDが見つかりません", type: .error)
            return
        }
        
        isLoading = true
        showResult = false
        
        let result = await profileUpdateRepository.updateProfile(
            userId: userId,
            username: nickname.isEmpty ? "名無し" : nickname,
            icon: profileImage.isEmpty ? "https://imgur.com/a/dsfJeyk" : profileImage
        )
        
        isLoading = false
        
        switch result {
        case .success(let message):
            showResult(message: message, type: .success)
            updateSuccess = true
            // SearchViewに遷移
            navigationDestination = .search
            
        case .error(let message):
            showResult(message: message, type: .error)
        }
    }
    
    private func showResult(message: String, type: ResultType) {
        resultMessage = message
        resultType = type
        showResult = true
    }
    
    func clearResult() {
        showResult = false
        resultMessage = ""
        resultType = .none
    }
    
    func resetNavigation() {
        navigationDestination = nil
    }
}
