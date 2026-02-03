import Foundation

/// 生物力学分析指标
/// Contains biomechanical metrics calculated from pose landmarks.
struct BiomechanicsMetrics: Equatable {
    
    // MARK: - 关节角度 (Joint Angles)
    
    /// 左膝关节屈曲角度 (度)
    /// Left knee flexion angle in degrees.
    let leftKneeFlexion: Float?
    
    /// 右膝关节屈曲角度 (度)
    /// Right knee flexion angle in degrees.
    let rightKneeFlexion: Float?
    
    /// 左肘关节角度 (度)
    /// Left elbow angle in degrees.
    let leftElbowAngle: Float?
    
    /// 右肘关节角度 (度)
    /// Right elbow angle in degrees.
    let rightElbowAngle: Float?
    
    // MARK: - 躯干旋转 (Torso Rotation)
    
    /// 肩部旋转角度 (度，相对于中性位置)
    /// Shoulder rotation angle in degrees relative to neutral position.
    let shoulderRotation: Float?
    
    /// 髋部旋转角度 (度，相对于中性位置)
    /// Hip rotation angle in degrees relative to neutral position.
    let hipRotation: Float?
    
    /// 髋肩分离度 (度)
    /// Hip-shoulder separation angle in degrees.
    /// This is a key metric for serve power generation.
    var hipShoulderSeparation: Float? {
        guard let shoulder = shoulderRotation,
              let hip = hipRotation else { return nil }
        return abs(shoulder - hip)
    }
    
    // MARK: - 位置与高度 (Position & Height)
    
    /// 击球点高度 (米)
    /// Contact point height in meters above ground.
    let contactHeight: Float?
    
    /// 左手腕高度 (米)
    /// Left wrist height in meters.
    let leftWristHeight: Float?
    
    /// 右手腕高度 (米)
    /// Right wrist height in meters.
    let rightWristHeight: Float?
    
    // MARK: - 速度 (Velocity)
    
    /// 右手腕速度 (米/秒)
    /// Right wrist velocity in m/s (proxy for racket head speed).
    let rightWristVelocity: Float?
    
    /// 左手腕速度 (米/秒)
    /// Left wrist velocity in m/s.
    let leftWristVelocity: Float?
    
    // MARK: - 时间戳
    
    /// 指标计算时的时间戳
    let timestamp: TimeInterval
    
    // MARK: - 质量检查
    
    /// 是否是有效的分析结果（至少有一个关键指标不为nil）
    var isValid: Bool {
        return leftKneeFlexion != nil ||
               rightKneeFlexion != nil ||
               hipShoulderSeparation != nil ||
               contactHeight != nil ||
               rightWristVelocity != nil
    }
}

// MARK: - 关节索引常量
/// MediaPipe Pose Landmark Indices
/// Reference: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker
extension BiomechanicsMetrics {
    
    enum LandmarkIndex {
        // Face
        static let nose = 0
        
        // Upper Body
        static let leftShoulder = 11
        static let rightShoulder = 12
        
        // Arms
        static let leftElbow = 13
        static let rightElbow = 14
        static let leftWrist = 15
        static let rightWrist = 16
        
        // Hands
        static let leftPinky = 17
        static let rightPinky = 18
        static let leftIndex = 19
        static let rightIndex = 20
        static let leftThumb = 21
        static let rightThumb = 22
        
        // Lower Body
        static let leftHip = 23
        static let rightHip = 24
        static let leftKnee = 25
        static let rightKnee = 26
        static let leftAnkle = 27
        static let rightAnkle = 28
        static let leftHeel = 29
        static let rightHeel = 30
        static let leftFootIndex = 31
        static let rightFootIndex = 32
    }
}
