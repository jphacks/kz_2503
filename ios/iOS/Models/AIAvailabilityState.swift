//
//  AIAvailabilityState.swift
//  iOS
//
//  Created by AI Assistant on 2025/01/27.
//

import Foundation

enum AIAvailabilityState {
    case available
    case deviceNotEligible
    case notEnabled
    case modelNotReady
    case simulator
    case other(String)
}
