import SwiftUI
import Vision
import AVFoundation
import Combine

/// スクロール要求を表現する構造体
struct ScrollRequest: Identifiable, Equatable {
    let id = UUID()
    let direction: ScrollDirection
}

enum ScrollDirection {
    case up, down
}

/// ウィンクの状態を管理するenum
private enum WinkState: CustomStringConvertible {
    case eyesOpen
    case winkStarted(eye: WinkedEye, timestamp: Date)
    
    enum WinkedEye {
        case left, right
    }
    
    var description: String {
        switch self {
        case .eyesOpen:
            return "両目開いている"
        case .winkStarted(let eye, let timestamp):
            let duration = Date().timeIntervalSince(timestamp)
            let eyeStr = eye == .left ? "左目" : "右目"
            return "\(eyeStr)ウィンク中 (\(String(format: "%.2f", duration))秒)"
        }
    }
}

class HandsFreeViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties for View
    @Published var isHandsFreeModeOn = false
    @Published var isFaceDetected = false
    @Published var scrollRequest: ScrollRequest?

    // MARK: - Camera and Vision Properties
    let cameraService = CameraService()
    private let visionQueue = DispatchQueue(label: "vision.queue", qos: .userInitiated)

    // MARK: - Wink Detection State
    private var winkState: WinkState = .eyesOpen
    private var lastScrollTime: Date?
    private var baselineLeftEyeOpenness: CGFloat = 0.0
    private var baselineRightEyeOpenness: CGFloat = 0.0
    private var baselineFrameCount = 0 // ベースライン確立用のフレームカウンタ
    private let baselineFramesNeeded = 10 // ベースライン確立に必要なフレーム数
    // フリッカー抑制用の追跡情報
    private var trackedFaceUUID: UUID?
    private var trackedBoundingBox: CGRect?
    private var consecutiveDetections = 0
    private var consecutiveMisses = 0
    private let detectionOnThreshold = 2     // 何フレーム連続検出でONにするか
    private let detectionOffThreshold = 5    // 何フレーム連続未検出でOFFにするか
    
    // トラッキング状態を定期的に表示するためのタイマー
    private var trackingStatusTimer: Timer?
    
    // 📌 追加：このセッションで一度でも顔を検出したかを記録するフラグ
    private var hasDetectedFaceInThisSession = false

    override init() {
        super.init()
        cameraService.setDelegate(self)
    }

    func toggleHandsFreeMode() {
        DispatchQueue.main.async {
            self.isHandsFreeModeOn.toggle()
            if self.isHandsFreeModeOn {
                self.cameraService.startSession()
                self.startTrackingStatusTimer()
                // ベースラインをリセット
                self.baselineLeftEyeOpenness = 0.0
                self.baselineRightEyeOpenness = 0.0
                self.baselineFrameCount = 0
                print("【ウィンク検出】: ベースライン初期化開始")
            } else {
                self.cameraService.stopSession()
                self.isFaceDetected = false
                self.trackedFaceUUID = nil
                self.trackedBoundingBox = nil
                self.consecutiveDetections = 0
                self.consecutiveMisses = 0
                self.stopTrackingStatusTimer()
                // 📌 モードOFFでフラグをリセット
                self.hasDetectedFaceInThisSession = false
                // ベースラインをリセット
                self.baselineLeftEyeOpenness = 0.0
                self.baselineRightEyeOpenness = 0.0
                self.baselineFrameCount = 0
            }
        }
    }
    
    // MARK: - Status Timer
    private func startTrackingStatusTimer() {
        trackingStatusTimer?.invalidate()
        trackingStatusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.printTrackingStatus()
        }
    }
    
    private func stopTrackingStatusTimer() {
        trackingStatusTimer?.invalidate()
        trackingStatusTimer = nil
        print("【トラッキングステータス】: 停止しました。")
    }
    
    private func printTrackingStatus() {
        if let uuid = trackedFaceUUID {
            print("【トラッキングステータス】: ✅ 追跡中 (ID: \(uuid.uuidString.prefix(8)))")
        } else {
            print("【トラッキングステータス】: ❌ 探査中 (Searching for face)")
        }
    }
    
    // MARK: - Vision Processing
    private func processFrame(_ buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self else { return }
            
            guard let observations = request.results as? [VNFaceObservation], !observations.isEmpty else {
                // ミスをカウントし、しきい値を超えたときだけOFFにする
                self.consecutiveMisses += 1
                self.consecutiveDetections = 0
                if self.consecutiveMisses >= self.detectionOffThreshold {
                    DispatchQueue.main.async { self.isFaceDetected = false }
                    self.trackedFaceUUID = nil
                    self.trackedBoundingBox = nil
                    self.resetWinkState()
                }
                return
            }
            
            var targetObservation: VNFaceObservation?

            // まずIoUで前回の顔に最も近いものを選択。なければ最大の顔を選ぶ
            if let prevBox = self.trackedBoundingBox {
                var bestIoU: CGFloat = 0
                var bestObs: VNFaceObservation?
                for obs in observations {
                    let iou = self.intersectionOverUnion(prevBox, obs.boundingBox)
                    if iou > bestIoU {
                        bestIoU = iou
                        bestObs = obs
                    }
                }
                // IoUが低すぎる場合は最大領域の顔にフォールバック
                if bestIoU > 0.1, let chosen = bestObs {
                    targetObservation = chosen
                } else {
                    targetObservation = observations.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
                }
            } else {
                targetObservation = observations.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
            }
            
            if let observation = targetObservation {
                if !self.hasDetectedFaceInThisSession {
                    print("【初回顔検出】: ✅ 成功！トラッキングを開始します。")
                    // フラグをtrueにして、次回以降は表示しないようにする
                    self.hasDetectedFaceInThisSession = true
                }
                // 命中をカウントし、しきい値を超えたときだけONにする
                self.consecutiveDetections += 1
                self.consecutiveMisses = 0
                if self.consecutiveDetections >= self.detectionOnThreshold {
                    DispatchQueue.main.async { self.isFaceDetected = true }
                }
                // 追跡情報を更新（スムージング）
                let newBox = observation.boundingBox
                if let prev = self.trackedBoundingBox {
                    let alpha: CGFloat = 0.7
                    self.trackedBoundingBox = CGRect(
                        x: prev.origin.x * alpha + newBox.origin.x * (1 - alpha),
                        y: prev.origin.y * alpha + newBox.origin.y * (1 - alpha),
                        width: prev.size.width * alpha + newBox.size.width * (1 - alpha),
                        height: prev.size.height * alpha + newBox.size.height * (1 - alpha)
                    )
                } else {
                    self.trackedBoundingBox = newBox
                }
                self.trackedFaceUUID = observation.uuid
                self.handleEyeAction(faceObservation: observation)
            } else {
                // 適切なターゲットが選べない場合はミス扱い
                self.consecutiveMisses += 1
                self.consecutiveDetections = 0
                if self.consecutiveMisses >= self.detectionOffThreshold {
                    DispatchQueue.main.async { self.isFaceDetected = false }
                    self.resetWinkState()
                    self.trackedFaceUUID = nil
                    self.trackedBoundingBox = nil
                }
            }
        }
        
//        let currentOrientation = self.currentImageOrientation()
        let handler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Visionリクエストの実行に失敗しました: \(error)")
        }
    }
    
    private func handleEyeAction(faceObservation: VNFaceObservation) {
        guard let landmarks = faceObservation.landmarks else { return }
        
        let currentLeftEyeOpenness = self.calculateEyeOpenness(for: landmarks.leftEye)
        let currentRightEyeOpenness = self.calculateEyeOpenness(for: landmarks.rightEye)
        
        // ベースラインの確立（最初の数フレーム）
        if baselineFrameCount < baselineFramesNeeded {
            if baselineFrameCount == 0 {
                baselineLeftEyeOpenness = currentLeftEyeOpenness
                baselineRightEyeOpenness = currentRightEyeOpenness
            } else {
                baselineLeftEyeOpenness = (baselineLeftEyeOpenness * CGFloat(baselineFrameCount) + currentLeftEyeOpenness) / CGFloat(baselineFrameCount + 1)
                baselineRightEyeOpenness = (baselineRightEyeOpenness * CGFloat(baselineFrameCount) + currentRightEyeOpenness) / CGFloat(baselineFrameCount + 1)
            }
            baselineFrameCount += 1
            
            if baselineFrameCount == baselineFramesNeeded {
                print("【ウィンク検出】: ベースライン確立完了 - 左目: \(String(format: "%.4f", baselineLeftEyeOpenness)), 右目: \(String(format: "%.4f", baselineRightEyeOpenness))")
            }
            return
        }
        
        // ウィンク検出の閾値を調整（より敏感に）
        let winkCloseThreshold: CGFloat = 0.5  // 0.4 -> 0.5 に緩和
        let winkOpenThreshold: CGFloat = 0.7   // 0.6 -> 0.7 に緩和

        var didLeftEyeClose = false
        var didRightEyeClose = false

        if currentLeftEyeOpenness < baselineLeftEyeOpenness * winkCloseThreshold {
            didLeftEyeClose = true
        }
        
        if currentRightEyeOpenness < baselineRightEyeOpenness * winkCloseThreshold {
            didRightEyeClose = true
        }

        // デバッグログ（10フレームに1回表示）
        if Int.random(in: 0..<10) == 0 {
            print("【ウィンク検出】目の状態 - 左目: \(String(format: "%.4f", currentLeftEyeOpenness)) (閾値: \(String(format: "%.4f", baselineLeftEyeOpenness * winkCloseThreshold))), 右目: \(String(format: "%.4f", currentRightEyeOpenness)) (閾値: \(String(format: "%.4f", baselineRightEyeOpenness * winkCloseThreshold))), 状態: \(winkState)")
        }

        switch winkState {
        case .eyesOpen:
            if didLeftEyeClose && !didRightEyeClose {
                winkState = .winkStarted(eye: .left, timestamp: Date())
                print("【ウィンク検出】: 👁️ 左目ウィンク開始検出！")
            } else if didRightEyeClose && !didLeftEyeClose {
                winkState = .winkStarted(eye: .right, timestamp: Date())
                print("【ウィンク検出】: 👁️ 右目ウィンク開始検出！")
            } else {
                // 両目が開いている場合のみベースラインを微調整
                if !didLeftEyeClose && !didRightEyeClose {
                    baselineLeftEyeOpenness = (baselineLeftEyeOpenness * 0.98) + (currentLeftEyeOpenness * 0.02)
                    baselineRightEyeOpenness = (baselineRightEyeOpenness * 0.98) + (currentRightEyeOpenness * 0.02)
                }
            }
            
        case .winkStarted(let eye, let timestamp):
            let duration = Date().timeIntervalSince(timestamp)
            
            var isWinkContinuing = false
            if eye == .left && didLeftEyeClose && currentLeftEyeOpenness < baselineLeftEyeOpenness * winkOpenThreshold {
                isWinkContinuing = true
            } else if eye == .right && didRightEyeClose && currentRightEyeOpenness < baselineRightEyeOpenness * winkOpenThreshold {
                isWinkContinuing = true
            }
            
            if isWinkContinuing {
                // ウィンク持続時間を1.0秒から0.3秒に短縮
                if duration >= 0.3 {
                    if let lastScroll = lastScrollTime, Date().timeIntervalSince(lastScroll) < 1.5 {
                        print("【ウィンク検出】: ⏳ クールダウン中（前回のスクロールから1.5秒待機）")
                    } else {
                        print("【ウィンク検出】: ✅ ウィンク確定！スクロールを実行します (方向: \(eye == .left ? "⬆️ 上" : "⬇️ 下"))")
                        triggerScroll(for: eye)
                        winkState = .eyesOpen
                    }
                }
            } else {
                print("【ウィンク検出】: ❌ ウィンク中断（\(String(format: "%.2f", duration))秒後）")
                winkState = .eyesOpen
            }
        }
    }
    
    private func triggerScroll(for eye: WinkState.WinkedEye) {
        lastScrollTime = Date()
        let direction: ScrollDirection = (eye == .right) ? .down : .up
        
        print("【ウィンク検出】: 📨 スクロール要求を送信 - 方向: \(direction == .up ? "⬆️ 上" : "⬇️ 下")")
        
        DispatchQueue.main.async {
            self.scrollRequest = ScrollRequest(direction: direction)
        }
    }
    
    private func resetWinkState() {
        winkState = .eyesOpen
        print("【ウィンク検出】: 🔄 ウィンク状態をリセット")
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
    
//    private func currentImageOrientation() -> CGImagePropertyOrientation {
//        let interfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
//
//        switch interfaceOrientation {
//        case .portrait: return .right
//        case .portraitUpsideDown: return .left
//        case .landscapeLeft: return .down
//        case .landscapeRight: return .up
//        default: return .right
//        }
//    }
}

extension HandsFreeViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // デバッグ: フレーム受信を確認
        #if DEBUG
        print("[Camera] sampleBuffer received. orientation=\(connection.videoOrientation.rawValue)")
        #endif
        // 📌 修正点 2: connectionから現在の映像の向きを取得する
        let videoOrientation = connection.videoOrientation
                
        // 📌 修正点 3: 取得した向きをVisionが理解できる形式に変換する
        let imageOrientation = videoOrientationToImageOrientation(videoOrientation)
        
        visionQueue.async {
            // 📌 修正点 4: processFrameに変換後の向きを渡す
            self.processFrame(sampleBuffer, orientation: imageOrientation)
        }
    }
    
    // 📌 追加：AVCaptureVideoOrientationをCGImagePropertyOrientationに変換するヘルパー関数
    private func videoOrientationToImageOrientation(_ videoOrientation: AVCaptureVideoOrientation) -> CGImagePropertyOrientation {
        switch videoOrientation {
        case .portrait:
            // フロントカメラの場合、ポートレートは右に90度回転した状態
            return .right
        case .portraitUpsideDown:
            return .left
        case .landscapeRight:
            return .up
        case .landscapeLeft:
            return .down
        @unknown default:
            return .right
        }
    }

    // IoU (Intersection over Union) を計算（Visionの正規化座標系 [0,1] 前提）
    private func intersectionOverUnion(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let inter = a.intersection(b)
        if inter.isNull { return 0 }
        let interArea = inter.width * inter.height
        let unionArea = a.width * a.height + b.width * b.height - interArea
        if unionArea <= 0 { return 0 }
        return interArea / unionArea
    }
}
