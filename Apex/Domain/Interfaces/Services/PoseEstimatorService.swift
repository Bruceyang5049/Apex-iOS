import Foundation
import AVFoundation
import Combine

/// 姿势估计服务接口
/// Protocol defining the contract for pose estimation services.
/// Follows Dependency Inversion Principle to allow swapping the underlying AI engine (e.g., MediaPipe, Vision).
protocol PoseEstimatorService {
    /// 初始化服务
    /// - Returns: A publisher that emits void on success or an error on failure.
    func initialize() async throws
    
    /// 处理单个视频帧进行姿势估计
    /// - Parameter sampleBuffer: The video frame buffer from the camera.
    /// - Returns: An asynchronous stream of results (or a single result).
    ///   For real-time, we might prefer a Combine publisher or AsyncStream in the implementation.
    ///   Here we define a method to process a frame and return the result asynchronously.
    func process(sampleBuffer: CMSampleBuffer) async throws -> PoseEstimationResult
    
    /// 处理像素缓冲区 (用于非实时或预处理的图像)
    /// - Parameter pixelBuffer: The CVPixelBuffer containing the image.
    /// - Parameter timestamp: The timestamp of the frame.
    func process(pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) async throws -> PoseEstimationResult
}
