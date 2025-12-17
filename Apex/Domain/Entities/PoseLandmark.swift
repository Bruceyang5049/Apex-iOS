import Foundation
import CoreGraphics

/// 3D 姿势地标实体
/// Represents a single landmark in 3D space, decoupled from any specific ML framework.
/// 对应 MediaPipe 的 NormalizedLandmark 或 WorldLandmark。
struct PoseLandmark: Identifiable, Equatable {
    let id: Int
    /// Normalized x coordinate [0, 1] or World x (meters)
    let x: Float
    /// Normalized y coordinate [0, 1] or World y (meters)
    let y: Float
    /// Normalized z coordinate or World z (meters)
    let z: Float
    /// Visibility score [0, 1]
    let visibility: Float
    /// Presence score [0, 1]
    let presence: Float
    
    /// 转换为 CGPoint (用于 2D 绘图)
    func toCGPoint(width: CGFloat, height: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat(x) * width, y: CGFloat(y) * height)
    }
}

/// 姿势估计结果实体
/// Represents the result of a pose estimation process for a single frame.
struct PoseEstimationResult: Equatable {
    /// 33 个身体关键点
    let landmarks: [PoseLandmark]
    /// 时间戳 (秒)
    let timestamp: TimeInterval
    
    /// 获取特定关键点
    func landmark(for index: Int) -> PoseLandmark? {
        guard index >= 0 && index < landmarks.count else { return nil }
        return landmarks[index]
    }
}
