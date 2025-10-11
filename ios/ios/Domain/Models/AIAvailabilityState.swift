import Foundation

enum AIAvailabilityState {
    case available, deviceNotEligible, notEnabled, modelNotReady, simulator
    case other(String)
}
