import Foundation

/// 生物力学分析器
/// Analyzes pose landmarks to extract biomechanical metrics for tennis serve analysis.
class BiomechanicsAnalyzer {
    
    // MARK: - Configuration
    
    /// 校准参数：用户身高 (米)
    /// Used to convert normalized/world coordinates to real-world measurements.
    var userHeight: Float?
    
    /// 像素到米的缩放比例 (自动计算或手动设置)
    private var pixelToMeterScale: Float?
    
    // MARK: - Filters
    
    /// 关键关节的平滑滤波器 (One Euro Filter)
    /// 33个关键点，每个都有独立的3D滤波器
    private var landmarkFilters: [Point3DFilter] = (0..<33).map { _ in
        Point3DFilter(minCutoff: 1.0, beta: 0.007, derivativeCutoff: 1.0)
    }
    
    /// 上一帧的关键点 (用于速度计算)
    private var previousLandmarks: [PoseLandmark]?
    private var previousTimestamp: TimeInterval?
    
    // MARK: - Public Methods
    
    /// 分析姿势并提取生物力学指标
    /// - Parameter result: 姿势估计结果
    /// - Returns: 生物力学指标
    func analyze(poseResult: PoseEstimationResult) -> BiomechanicsMetrics {
        // 1. 平滑关键点数据
        let smoothedLandmarks = smoothLandmarks(poseResult.landmarks, timestamp: poseResult.timestamp)
        
        // 2. 自动校准 (如果未设置)
        if pixelToMeterScale == nil {
            calibrateFromPose(smoothedLandmarks)
        }
        
        // 3. 计算关节角度
        let leftKnee = calculateKneeFlexion(landmarks: smoothedLandmarks, isLeft: true)
        let rightKnee = calculateKneeFlexion(landmarks: smoothedLandmarks, isLeft: false)
        let leftElbow = calculateElbowAngle(landmarks: smoothedLandmarks, isLeft: true)
        let rightElbow = calculateElbowAngle(landmarks: smoothedLandmarks, isLeft: false)
        
        // 4. 计算躯干旋转
        let shoulderRotation = calculateShoulderRotation(landmarks: smoothedLandmarks)
        let hipRotation = calculateHipRotation(landmarks: smoothedLandmarks)
        
        // 5. 计算高度 (需要校准)
        let leftWristHeight = calculateHeight(landmark: smoothedLandmarks[BiomechanicsMetrics.LandmarkIndex.leftWrist])
        let rightWristHeight = calculateHeight(landmark: smoothedLandmarks[BiomechanicsMetrics.LandmarkIndex.rightWrist])
        
        // 发球击球点通常是右手腕 (假设右手持拍)
        let contactHeight = rightWristHeight
        
        // 6. 计算速度
        let rightWristVelocity = calculateVelocity(
            currentLandmark: smoothedLandmarks[BiomechanicsMetrics.LandmarkIndex.rightWrist],
            landmarkIndex: BiomechanicsMetrics.LandmarkIndex.rightWrist,
            timestamp: poseResult.timestamp
        )
        
        let leftWristVelocity = calculateVelocity(
            currentLandmark: smoothedLandmarks[BiomechanicsMetrics.LandmarkIndex.leftWrist],
            landmarkIndex: BiomechanicsMetrics.LandmarkIndex.leftWrist,
            timestamp: poseResult.timestamp
        )
        
        // 7. 更新历史数据
        previousLandmarks = smoothedLandmarks
        previousTimestamp = poseResult.timestamp
        
        // 8. 构建结果
        return BiomechanicsMetrics(
            leftKneeFlexion: leftKnee,
            rightKneeFlexion: rightKnee,
            leftElbowAngle: leftElbow,
            rightElbowAngle: rightElbow,
            shoulderRotation: shoulderRotation,
            hipRotation: hipRotation,
            contactHeight: contactHeight,
            leftWristHeight: leftWristHeight,
            rightWristHeight: rightWristHeight,
            rightWristVelocity: rightWristVelocity,
            leftWristVelocity: leftWristVelocity,
            timestamp: poseResult.timestamp
        )
    }
    
    /// 重置分析器状态 (清除滤波器和历史数据)
    func reset() {
        landmarkFilters.forEach { $0.reset() }
        previousLandmarks = nil
        previousTimestamp = nil
        pixelToMeterScale = nil
    }
    
    // MARK: - Landmark Smoothing
    
    private func smoothLandmarks(_ landmarks: [PoseLandmark], timestamp: TimeInterval) -> [PoseLandmark] {
        return landmarks.enumerated().map { index, landmark in
            let filter = landmarkFilters[index]
            let smoothed = filter.filter(x: landmark.x, y: landmark.y, z: landmark.z, timestamp: timestamp)
            
            return PoseLandmark(
                id: landmark.id,
                x: smoothed.x,
                y: smoothed.y,
                z: smoothed.z,
                visibility: landmark.visibility,
                presence: landmark.presence
            )
        }
    }
    
    // MARK: - Calibration
    
    /// 基于姿势自动校准 (使用躯干长度作为参考)
    /// 假设 MediaPipe World Landmarks 已经以米为单位，但如果没有，我们可以用用户身高校准
    private func calibrateFromPose(_ landmarks: [PoseLandmark]) {
        guard let userHeight = userHeight else { return }
        
        // 计算躯干长度 (肩部中点到髋部中点的距离)
        let leftShoulder = landmarks[BiomechanicsMetrics.LandmarkIndex.leftShoulder]
        let rightShoulder = landmarks[BiomechanicsMetrics.LandmarkIndex.rightShoulder]
        let leftHip = landmarks[BiomechanicsMetrics.LandmarkIndex.leftHip]
        let rightHip = landmarks[BiomechanicsMetrics.LandmarkIndex.rightHip]
        
        let shoulderMid = midpoint(leftShoulder, rightShoulder)
        let hipMid = midpoint(leftHip, rightHip)
        
        let torsoLength = distance3D(shoulderMid, hipMid)
        
        // 躯干长度约占身高的 30% (经验值)
        let expectedTorsoLength = userHeight * 0.3
        
        // 如果 MediaPipe 输出不是米，计算缩放比例
        if torsoLength > 0 {
            pixelToMeterScale = expectedTorsoLength / torsoLength
        }
    }
    
    // MARK: - Joint Angle Calculations
    
    /// 计算膝关节屈曲角度
    /// - Parameters:
    ///   - landmarks: 姿势关键点
    ///   - isLeft: 是否是左膝
    /// - Returns: 角度 (度)
    private func calculateKneeFlexion(landmarks: [PoseLandmark], isLeft: Bool) -> Float? {
        let hipIdx = isLeft ? BiomechanicsMetrics.LandmarkIndex.leftHip : BiomechanicsMetrics.LandmarkIndex.rightHip
        let kneeIdx = isLeft ? BiomechanicsMetrics.LandmarkIndex.leftKnee : BiomechanicsMetrics.LandmarkIndex.rightKnee
        let ankleIdx = isLeft ? BiomechanicsMetrics.LandmarkIndex.leftAnkle : BiomechanicsMetrics.LandmarkIndex.rightAnkle
        
        let hip = landmarks[hipIdx]
        let knee = landmarks[kneeIdx]
        let ankle = landmarks[ankleIdx]
        
        // 检查可见性
        guard hip.visibility > 0.5 && knee.visibility > 0.5 && ankle.visibility > 0.5 else {
            return nil
        }
        
        return calculateAngle3D(point1: hip, vertex: knee, point2: ankle)
    }
    
    /// 计算肘关节角度
    private func calculateElbowAngle(landmarks: [PoseLandmark], isLeft: Bool) -> Float? {
        let shoulderIdx = isLeft ? BiomechanicsMetrics.LandmarkIndex.leftShoulder : BiomechanicsMetrics.LandmarkIndex.rightShoulder
        let elbowIdx = isLeft ? BiomechanicsMetrics.LandmarkIndex.leftElbow : BiomechanicsMetrics.LandmarkIndex.rightElbow
        let wristIdx = isLeft ? BiomechanicsMetrics.LandmarkIndex.leftWrist : BiomechanicsMetrics.LandmarkIndex.rightWrist
        
        let shoulder = landmarks[shoulderIdx]
        let elbow = landmarks[elbowIdx]
        let wrist = landmarks[wristIdx]
        
        guard shoulder.visibility > 0.5 && elbow.visibility > 0.5 && wrist.visibility > 0.5 else {
            return nil
        }
        
        return calculateAngle3D(point1: shoulder, vertex: elbow, point2: wrist)
    }
    
    /// 计算肩部旋转角度 (相对于水平面)
    private func calculateShoulderRotation(landmarks: [PoseLandmark]) -> Float? {
        let left = landmarks[BiomechanicsMetrics.LandmarkIndex.leftShoulder]
        let right = landmarks[BiomechanicsMetrics.LandmarkIndex.rightShoulder]
        
        guard left.visibility > 0.5 && right.visibility > 0.5 else { return nil }
        
        // 计算肩线相对于 x 轴的角度
        let dx = right.x - left.x
        let dz = right.z - left.z
        
        let angleRadians = atan2(dz, dx)
        return angleRadians * 180.0 / Float.pi
    }
    
    /// 计算髋部旋转角度
    private func calculateHipRotation(landmarks: [PoseLandmark]) -> Float? {
        let left = landmarks[BiomechanicsMetrics.LandmarkIndex.leftHip]
        let right = landmarks[BiomechanicsMetrics.LandmarkIndex.rightHip]
        
        guard left.visibility > 0.5 && right.visibility > 0.5 else { return nil }
        
        let dx = right.x - left.x
        let dz = right.z - left.z
        
        let angleRadians = atan2(dz, dx)
        return angleRadians * 180.0 / Float.pi
    }
    
    // MARK: - Height Calculation
    
    /// 计算关键点的实际高度 (米)
    private func calculateHeight(landmark: PoseLandmark) -> Float? {
        guard landmark.visibility > 0.5 else { return nil }
        
        // MediaPipe World Landmarks 的 y 坐标是向上为正的米制单位
        // 如果需要校准，应用缩放比例
        let scale = pixelToMeterScale ?? 1.0
        return landmark.y * scale
    }
    
    // MARK: - Velocity Calculation
    
    /// 计算关键点的速度 (米/秒)
    private func calculateVelocity(currentLandmark: PoseLandmark, landmarkIndex: Int, timestamp: TimeInterval) -> Float? {
        guard let prevLandmarks = previousLandmarks,
              let prevTimestamp = previousTimestamp,
              currentLandmark.visibility > 0.5 else {
            return nil
        }
        
        let previousLandmark = prevLandmarks[landmarkIndex]
        let dt = Float(timestamp - prevTimestamp)
        
        guard dt > 0 else { return nil }
        
        // 计算 3D 距离
        let dx = currentLandmark.x - previousLandmark.x
        let dy = currentLandmark.y - previousLandmark.y
        let dz = currentLandmark.z - previousLandmark.z
        
        let distance = sqrt(dx*dx + dy*dy + dz*dz)
        let scale = pixelToMeterScale ?? 1.0
        
        return (distance * scale) / dt
    }
    
    // MARK: - Geometry Helpers
    
    /// 计算两点的中点
    private func midpoint(_ p1: PoseLandmark, _ p2: PoseLandmark) -> PoseLandmark {
        return PoseLandmark(
            id: -1,
            x: (p1.x + p2.x) / 2,
            y: (p1.y + p2.y) / 2,
            z: (p1.z + p2.z) / 2,
            visibility: min(p1.visibility, p2.visibility),
            presence: min(p1.presence, p2.presence)
        )
    }
    
    /// 计算 3D 空间两点距离
    private func distance3D(_ p1: PoseLandmark, _ p2: PoseLandmark) -> Float {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let dz = p2.z - p1.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    /// 计算 3D 空间中的角度 (以 vertex 为顶点)
    /// - Returns: 角度 (度)
    private func calculateAngle3D(point1: PoseLandmark, vertex: PoseLandmark, point2: PoseLandmark) -> Float {
        // 构建向量
        let v1 = (
            x: point1.x - vertex.x,
            y: point1.y - vertex.y,
            z: point1.z - vertex.z
        )
        
        let v2 = (
            x: point2.x - vertex.x,
            y: point2.y - vertex.y,
            z: point2.z - vertex.z
        )
        
        // 计算向量模长
        let mag1 = sqrt(v1.x*v1.x + v1.y*v1.y + v1.z*v1.z)
        let mag2 = sqrt(v2.x*v2.x + v2.y*v2.y + v2.z*v2.z)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        // 点积
        let dot = v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
        
        // 夹角余弦
        let cosTheta = dot / (mag1 * mag2)
        
        // 防止浮点误差导致 acos 越界
        let clampedCos = max(-1.0, min(1.0, cosTheta))
        
        // 转换为角度
        let angleRadians = acos(clampedCos)
        return angleRadians * 180.0 / Float.pi
    }
}
