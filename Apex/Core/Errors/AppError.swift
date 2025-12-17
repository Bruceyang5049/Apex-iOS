import Foundation

/// 应用全局错误枚举
/// Defines the fundamental error types for the APEX application.
enum AppError: Error, LocalizedError {
    case cameraAccessDenied
    case poseEstimationFailed(reason: String)
    case invalidVideoFrame
    case modelInitializationFailed
    case unknown(error: Error)

    var errorDescription: String? {
        switch self {
        case .cameraAccessDenied:
            return "无法访问相机，请在设置中开启权限。"
        case .poseEstimationFailed(let reason):
            return "姿势识别失败: \(reason)"
        case .invalidVideoFrame:
            return "无效的视频帧数据。"
        case .modelInitializationFailed:
            return "AI 模型初始化失败。"
        case .unknown(let error):
            return "发生未知错误: \(error.localizedDescription)"
        }
    }
}
