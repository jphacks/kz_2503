import SwiftUI
import Vision
import AVFoundation
import Combine

/// スクロール方向を表現するenum
enum ScrollDirection {
    case up, down
}

/// スクロール要求を表現する構造体
struct ScrollRequest: Identifiable, Equatable {
    let id = UUID()
    let direction: ScrollDirection
}

class HandsFreeViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties for View
    @Published var isHandsFreeModeOn = false
    @Published var isFaceDetected = false
    @Published var scrollRequest: ScrollRequest?
    @Published var voiceInputEnabled = false
    @Published var autoScrollEnabled = false // 自動スクロール（ウィンク検出）が有効かどうか
    @Published var latestVoiceText: String? // 音声入力でキャプチャした最新の文章（1つのみ）
    
    // MARK: - Services
    let cameraService = CameraService()
    private let winkDetectionService = WinkDetectionService()
    private let voiceRecognitionService = VoiceRecognitionService()
    
    // MARK: - Private Properties
    private let visionQueue = DispatchQueue(label: "vision.queue", qos: .userInitiated)
    var isScrollingSuppressed: Bool = false {
        didSet {
            winkDetectionService.isScrollingSuppressed = isScrollingSuppressed
        }
    }
    
    // フリッカー抑制用の追跡情報
    private var trackedFaceUUID: UUID?
    private var trackedBoundingBox: CGRect?
    private var consecutiveDetections = 0
    private var consecutiveMisses = 0
    private let detectionOnThreshold = 2
    private let detectionOffThreshold = 5
    
    // トラッキング状態を定期的に表示するためのタイマー
    private var trackingStatusTimer: Timer?
    
    override init() {
        super.init()
        cameraService.setDelegate(self)
        setupServices()
    }
    
    // MARK: - Setup
    private func setupServices() {
        // ウィンク検出サービスのコールバック設定
        winkDetectionService.onScrollRequest = { [weak self] request in
            DispatchQueue.main.async {
                self?.scrollRequest = request
            }
        }
        
        winkDetectionService.onFaceDetected = { [weak self] isDetected in
            DispatchQueue.main.async {
                self?.isFaceDetected = isDetected
            }
        }
        
        // 音声認識サービスのコールバック設定
        voiceRecognitionService.onTextCaptured = { [weak self] capturedText in
            guard let self = self else { return }
            self.latestVoiceText = capturedText
            print("【HandsFreeViewModel】: 📝 最新の音声テキストを更新: 「\(capturedText)」")
        }
    }
    
    // MARK: - Public Methods
    func toggleHandsFreeMode() {
        DispatchQueue.main.async {
            self.isHandsFreeModeOn.toggle()
            if self.isHandsFreeModeOn {
                self.startHandsFreeMode()
            } else {
                self.stopHandsFreeMode()
            }
        }
    }
    
    /// 設定変更時の処理（自動スクロールのON/OFF切り替え時）
    func updateCameraBasedOnSettings() {
        guard isHandsFreeModeOn else { return }
        
        if autoScrollEnabled {
            // 自動スクロールがONになった場合、カメラを起動
            if !cameraService.isSessionRunning {
                cameraService.startSession()
                startTrackingStatusTimer()
            }
        } else {
            // 自動スクロールがOFFになった場合、カメラを停止
            if cameraService.isSessionRunning {
                cameraService.stopSession()
                stopTrackingStatusTimer()
                isFaceDetected = false
            }
        }
    }
    
    // MARK: - Private Methods
    private func startHandsFreeMode() {
        // カメラは自動スクロールがONの時のみ起動
        if autoScrollEnabled {
            cameraService.startSession()
            startTrackingStatusTimer()
        }
        
        // ウィンク検出サービスの設定
        winkDetectionService.isEnabled = autoScrollEnabled // 自動スクロールがONの時のみウィンク検出を有効化
        winkDetectionService.resetBaseline()
        winkDetectionService.resetTracking()
        
        // 音声入力が有効な場合は音声認識を開始
        if voiceInputEnabled {
            voiceRecognitionService.startRecognition()
        }
    }
    
    private func stopHandsFreeMode() {
        cameraService.stopSession()
        isFaceDetected = false
        trackedFaceUUID = nil
        trackedBoundingBox = nil
        consecutiveDetections = 0
        consecutiveMisses = 0
        stopTrackingStatusTimer()
        
        // サービスのリセット
        winkDetectionService.resetTracking()
        
        // 音声認識を停止
        if voiceRecognitionService.isRecognizing {
            voiceRecognitionService.stopRecognition()
        }
    }
    
    // MARK: - Voice Text Management
    
    /// 最新の音声テキストをクリア
    func clearLatestVoiceText() {
        latestVoiceText = nil
        voiceRecognitionService.clearLatestText()
        print("【HandsFreeViewModel】: 🗑️ 最新の音声テキストをクリアしました")
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
                self.handleNoFaceDetected()
                return
            }
            
            // 最適な顔を選択
            if let targetObservation = self.selectBestFace(from: observations) {
                self.handleFaceDetected(targetObservation)
            } else {
                self.handleNoFaceDetected()
            }
        }
        
        let handler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Visionリクエストの実行に失敗しました: \(error)")
        }
    }
    
    private func selectBestFace(from observations: [VNFaceObservation]) -> VNFaceObservation? {
        // IoUで前回の顔に最も近いものを選択。なければ最大の顔を選ぶ
        if let prevBox = trackedBoundingBox {
            var bestIoU: CGFloat = 0
            var bestObs: VNFaceObservation?
            for obs in observations {
                let iou = intersectionOverUnion(prevBox, obs.boundingBox)
                if iou > bestIoU {
                    bestIoU = iou
                    bestObs = obs
                }
            }
            // IoUが低すぎる場合は最大領域の顔にフォールバック
            if bestIoU > 0.1, let chosen = bestObs {
                return chosen
            } else {
                return observations.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
            }
        } else {
            return observations.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height })
        }
    }
    
    private func handleFaceDetected(_ observation: VNFaceObservation) {
        // 命中をカウント
        consecutiveDetections += 1
        consecutiveMisses = 0
        if consecutiveDetections >= detectionOnThreshold {
            DispatchQueue.main.async { self.isFaceDetected = true }
        }
        
        // 追跡情報を更新（スムージング）
        let newBox = observation.boundingBox
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
        trackedFaceUUID = observation.uuid
        
        // ウィンク検出サービスに処理を委譲
        winkDetectionService.processFrame(observation)
    }
    
    private func handleNoFaceDetected() {
        consecutiveMisses += 1
        consecutiveDetections = 0
        if consecutiveMisses >= detectionOffThreshold {
            DispatchQueue.main.async { self.isFaceDetected = false }
            trackedFaceUUID = nil
            trackedBoundingBox = nil
            winkDetectionService.handleFaceLost()
        }
    }
    
    // IoU (Intersection over Union) を計算
    private func intersectionOverUnion(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let inter = a.intersection(b)
        if inter.isNull { return 0 }
        let interArea = inter.width * inter.height
        let unionArea = a.width * a.height + b.width * b.height - interArea
        if unionArea <= 0 { return 0 }
        return interArea / unionArea
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension HandsFreeViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let videoOrientation = connection.videoOrientation
        let imageOrientation = videoOrientationToImageOrientation(videoOrientation)
        
        visionQueue.async {
            self.processFrame(sampleBuffer, orientation: imageOrientation)
        }
    }
    
    private func videoOrientationToImageOrientation(_ videoOrientation: AVCaptureVideoOrientation) -> CGImagePropertyOrientation {
        switch videoOrientation {
        case .portrait:
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
}
