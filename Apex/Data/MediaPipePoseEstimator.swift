import Foundation
import MediaPipeTasksVision
import AVFoundation

/// MediaPipe 姿势估计的具体实现
/// Concrete implementation of PoseEstimatorService using Google MediaPipe.
class MediaPipePoseEstimator: PoseEstimatorService {
    
    private var poseLandmarker: PoseLandmarker?
    
    init() {}
    
    func initialize() async throws {
        // 1. 获取模型路径
        guard let modelPath = Bundle.main.path(forResource: "pose_landmarker_full", ofType: "task") else {
            let errorMsg = "❌ MODEL FILE NOT FOUND: Check 'Copy Bundle Resources'. Ensure 'pose_landmarker_full.task' is added to the target."
            print(errorMsg)
            throw AppError.modelInitializationFailed
        }
        
        // 2. 配置 MediaPipe 选项
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video // 使用 Video 模式以支持时间戳和平滑，且保持同步返回
        options.numPoses = 1
        options.minPoseDetectionConfidence = 0.5
        
        // 3. 创建 Landmarker
        do {
            self.poseLandmarker = try PoseLandmarker(options: options)
            print("✅ MediaPipe PoseLandmarker initialized successfully.")
        } catch {
            print("❌ Failed to initialize PoseLandmarker: \(error)")
            throw AppError.modelInitializationFailed
        }
    }
    
    /// 处理 CMSampleBuffer (适配协议)
    func process(sampleBuffer: CMSampleBuffer) async throws -> PoseEstimationResult {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw AppError.invalidVideoFrame
        }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        return try await process(pixelBuffer: pixelBuffer, timestamp: timestamp)
    }
    
    /// 处理 PixelBuffer
    func process(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) async throws -> PoseEstimationResult {
        guard let landmarker = self.poseLandmarker else {
            throw AppError.modelInitializationFailed
        }
        
        // 将 TimeInterval (秒) 转换为 MediaPipe 需要的毫秒 (Int)
        let timestampMs = Int(timestamp * 1000)
        
        // MediaPipe 的 detectAsync 是基于回调的，我们需要将其转换为 async/await
        // We use `withCheckedThrowingContinuation` to bridge the callback-based API to async/await.
        return try await withCheckedThrowingContinuation { continuation in
            
            // 创建 MPImage
            guard let mpImage = try? MPImage(imageBuffer: pixelBuffer) else {
                continuation.resume(throwing: AppError.invalidVideoFrame)
                return
            }
            
            do {
                // 调用 MediaPipe 进行检测 (Video Mode)
                // 使用 .video 模式允许我们传入时间戳，这对于 MediaPipe 内部的平滑滤波至关重要。
                // detect(videoFrame:timestampMs:) 是同步方法，直接返回结果。
                let result = try landmarker.detect(videoFrame: mpImage, timestampInMilliseconds: timestampMs)
                let mappedResult = self.mapResult(result, timestamp: timestamp)
                continuation.resume(returning: mappedResult)
                
            } catch {
                continuation.resume(throwing: AppError.poseEstimationFailed(reason: error.localizedDescription))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapResult(_ result: PoseLandmarkerResult, timestamp: TimeInterval) -> PoseEstimationResult {
        // 提取第一个检测到的人 (numPoses = 1)
        guard let firstWorldLandmarks = result.worldLandmarks.first else {
            return PoseEstimationResult(landmarks: [], timestamp: timestamp)
        }
        
        // 映射关键点
        let landmarks = firstWorldLandmarks.enumerated().map { (index, landmark) in
            PoseLandmark(
                id: index,
                x: landmark.x,
                y: landmark.y,
                z: landmark.z,
                visibility: landmark.visibility.map { Float($0) } ?? 0.0,
                presence: landmark.presence.map { Float($0) } ?? 0.0
            )
        }
        
        return PoseEstimationResult(landmarks: landmarks, timestamp: timestamp)
    }
}
