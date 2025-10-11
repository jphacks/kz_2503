import Foundation
import Vision
import AVFoundation

/// ウィンクの状態を管理するenum
private enum WinkState: CustomStringConvertible {
    case eyesOpen
    case blinking(timestamp: Date)
    case winkStarted(eye: WinkedEye, timestamp: Date)
    
    enum WinkedEye {
        case left, right
    }
    
    var description: String {
        switch self {
        case .eyesOpen:
            return "両目開いている"
        case .blinking(let timestamp):
            let duration = Date().timeIntervalSince(timestamp)
            return "瞬き中 (\(String(format: "%.2f", duration))秒)"
        case .winkStarted(let eye, let timestamp):
            let duration = Date().timeIntervalSince(timestamp)
            let eyeStr = eye == .left ? "左目" : "右目"
            return "\(eyeStr)ウィンク中 (\(String(format: "%.2f", duration))秒)"
        }
    }
}

/// ウィンク検出サービス
class WinkDetectionService {
    // MARK: - Published Properties
    var onScrollRequest: ((ScrollRequest) -> Void)?
    var onFaceDetected: ((Bool) -> Void)?
    
    // MARK: - Control Flags
    var isEnabled: Bool = true // ウィンク検出が有効かどうか
    var isScrollingSuppressed: Bool = false
    
    // MARK: - Wink Detection State
    private var winkState: WinkState = .eyesOpen
    private var lastScrollTime: Date?
    private var baselineLeftEyeOpenness: CGFloat = 0.0
    private var baselineRightEyeOpenness: CGFloat = 0.0
    private var baselineFrameCount = 0
    private let baselineFramesNeeded = 10
    
    // MARK: - Face Tracking State
    private var trackedFaceUUID: UUID?
    private var trackedBoundingBox: CGRect?
    private var consecutiveDetections = 0
    private var consecutiveMisses = 0
    private let detectionOnThreshold = 2
    private let detectionOffThreshold = 5
    private var hasDetectedFaceInThisSession = false
    
    // MARK: - Public Methods
    func resetBaseline() {
        baselineLeftEyeOpenness = 0.0
        baselineRightEyeOpenness = 0.0
        baselineFrameCount = 0
    }
    
    func resetTracking() {
        trackedFaceUUID = nil
        trackedBoundingBox = nil
        consecutiveDetections = 0
        consecutiveMisses = 0
        hasDetectedFaceInThisSession = false
        resetBaseline()
        resetWinkState()
    }
    
    func processFrame(_ faceObservation: VNFaceObservation) {
        // ウィンク検出が無効の場合は処理しない
        guard isEnabled else { return }
        
        if !hasDetectedFaceInThisSession {
            print("【初回顔検出】: ✅ 成功！トラッキングを開始します。")
            hasDetectedFaceInThisSession = true
        }
        
        // 命中をカウント
        consecutiveDetections += 1
        consecutiveMisses = 0
        if consecutiveDetections >= detectionOnThreshold {
            onFaceDetected?(true)
        }
        
        // 追跡情報を更新（スムージング）
        let newBox = faceObservation.boundingBox
        if let prev = trackedBoundingBox {
            let alpha: CGFloat = 0.7
            trackedBoundingBox = CGRect(
                x: prev.origin.x * alpha + newBox.origin.x * (1 - alpha),
                y: prev.origin.y * alpha + newBox.origin.y * (1 - alpha),
                width: prev.size.width * alpha + newBox.size.width * (1 - alpha),
                height: prev.size.height * alpha + newBox.size.height * (1 - alpha)
            )
        } else {
            trackedBoundingBox = newBox
        }
        trackedFaceUUID = faceObservation.uuid
        
        handleEyeAction(faceObservation: faceObservation)
    }
    
    func handleFaceLost() {
        consecutiveMisses += 1
        consecutiveDetections = 0
        if consecutiveMisses >= detectionOffThreshold {
            onFaceDetected?(false)
            resetWinkState()
            trackedFaceUUID = nil
            trackedBoundingBox = nil
        }
    }
    
    // MARK: - Private Methods
    private func handleEyeAction(faceObservation: VNFaceObservation) {
        guard let landmarks = faceObservation.landmarks else { return }
        
        let currentLeftEyeOpenness = calculateEyeOpenness(for: landmarks.leftEye)
        let currentRightEyeOpenness = calculateEyeOpenness(for: landmarks.rightEye)
        
        // デバッグログ：左右の目の開き具合を比較
        print("【目の開き具合】左目: \(String(format: "%.3f", currentLeftEyeOpenness)), 右目: \(String(format: "%.3f", currentRightEyeOpenness))")
        print("【ベースライン】左目: \(String(format: "%.3f", baselineLeftEyeOpenness)), 右目: \(String(format: "%.3f", baselineRightEyeOpenness))")
        
        // ベースラインの確立
        if baselineFrameCount < baselineFramesNeeded {
            if baselineFrameCount == 0 {
                baselineLeftEyeOpenness = currentLeftEyeOpenness
                baselineRightEyeOpenness = currentRightEyeOpenness
            } else {
                baselineLeftEyeOpenness = (baselineLeftEyeOpenness * CGFloat(baselineFrameCount) + currentLeftEyeOpenness) / CGFloat(baselineFrameCount + 1)
                baselineRightEyeOpenness = (baselineRightEyeOpenness * CGFloat(baselineFrameCount) + currentRightEyeOpenness) / CGFloat(baselineFrameCount + 1)
            }
            baselineFrameCount += 1
            return
        }
        
        let closeThreshold: CGFloat = 0.5
        let wideOpenThreshold: CGFloat = 0.8
        
        let isLeftEyeClosed = currentLeftEyeOpenness < baselineLeftEyeOpenness * closeThreshold
        let isRightEyeClosed = currentRightEyeOpenness < baselineRightEyeOpenness * closeThreshold
        let isLeftEyeWideOpen = currentLeftEyeOpenness > baselineLeftEyeOpenness * wideOpenThreshold
        let isRightEyeWideOpen = currentRightEyeOpenness > baselineRightEyeOpenness * wideOpenThreshold
        
        switch winkState {
        case .eyesOpen:
            if isLeftEyeClosed && isRightEyeClosed {
                winkState = .blinking(timestamp: Date())
            } else if isLeftEyeClosed && isRightEyeWideOpen {
                if isScrollingSuppressed {
                    return
                }
                if let lastScroll = lastScrollTime, Date().timeIntervalSince(lastScroll) < 0.8 {
                    return
                }
                print("【ウィンク検出】: 👁️ 左目ウィンク検出！")
                print("【ウィンク検出】: 📊 スクロール方向: ⬆️ 上")
                triggerScroll(for: .left)
                winkState = .winkStarted(eye: .left, timestamp: Date())
            } else if isRightEyeClosed && isLeftEyeWideOpen {
                if isScrollingSuppressed {
                    return
                }
                if let lastScroll = lastScrollTime, Date().timeIntervalSince(lastScroll) < 0.8 {
                    return
                }
                print("【ウィンク検出】: 👁️ 右目ウィンク検出！")
                print("【ウィンク検出】: 📊 スクロール方向: ⬇️ 下")
                triggerScroll(for: .right)
                winkState = .winkStarted(eye: .right, timestamp: Date())
            } else if !isLeftEyeClosed && !isRightEyeClosed {
                baselineLeftEyeOpenness = (baselineLeftEyeOpenness * 0.98) + (currentLeftEyeOpenness * 0.02)
                baselineRightEyeOpenness = (baselineRightEyeOpenness * 0.98) + (currentRightEyeOpenness * 0.02)
            }
            
        case .blinking(let timestamp):
            if !isLeftEyeClosed && !isRightEyeClosed {
                winkState = .eyesOpen
            } else if Date().timeIntervalSince(timestamp) >= 0.5 {
                winkState = .eyesOpen
            }
            
        case .winkStarted(_, let timestamp):
            if !isLeftEyeClosed && !isRightEyeClosed {
                winkState = .eyesOpen
            } else if Date().timeIntervalSince(timestamp) >= 0.5 {
                winkState = .eyesOpen
            }
        }
    }
    
    private func triggerScroll(for eye: WinkState.WinkedEye) {
        lastScrollTime = Date()
        let direction: ScrollDirection = (eye == .right) ? .down : .up
        let request = ScrollRequest(direction: direction)
        onScrollRequest?(request)
    }
    
    private func resetWinkState() {
        winkState = .eyesOpen
    }
    
    private func calculateEyeOpenness(for eye: VNFaceLandmarkRegion2D?) -> CGFloat {
        guard let eye = eye else { return 0 }
        let points = eye.normalizedPoints
        guard points.count >= 4 else { return 0 }
        let topPoints = [points[1], points[2]]
        let bottomPoints = [points[5], points[4]]
        let avgTopY = topPoints.reduce(0) { $0 + $1.y } / CGFloat(topPoints.count)
        let avgBottomY = bottomPoints.reduce(0) { $0 + $1.y } / CGFloat(bottomPoints.count)
        return abs(avgTopY - avgBottomY)
    }
}

