import Foundation

/// 发球阶段枚举
/// Represents the different phases of a tennis serve motion.
enum ServePhase: String, Codable {
    case preparation      // 准备期: 静止站位
    case loading          // 蓄力期: 屈膝下蹲，后引拍
    case contact          // 击球期: 最高点接触球
    case followThrough    // 随挥期: 击球后动作完成
    
    var displayName: String {
        switch self {
        case .preparation: return "准备"
        case .loading: return "蓄力"
        case .contact: return "击球"
        case .followThrough: return "随挥"
        }
    }
    
    var emoji: String {
        switch self {
        case .preparation: return "🧍"
        case .loading: return "💪"
        case .contact: return "🎾"
        case .followThrough: return "✨"
        }
    }
}

/// 发球阶段事件
/// Records a detected serve phase transition with associated metrics.
struct ServePhaseEvent: Codable, Identifiable {
    let id: UUID
    let phase: ServePhase
    let timestamp: TimeInterval
    let keyMetrics: BiomechanicsMetrics
    var duration: TimeInterval?  // 阶段持续时间（在下一阶段开始时计算）
    
    init(phase: ServePhase, timestamp: TimeInterval, keyMetrics: BiomechanicsMetrics) {
        self.id = UUID()
        self.phase = phase
        self.timestamp = timestamp
        self.keyMetrics = keyMetrics
        self.duration = nil
    }
}

/// 发球阶段检测器
/// Detects serve phases using biomechanics metrics and time-series analysis.
class ServePhaseDetector {
    
    // MARK: - Configuration
    
    /// 检测阈值配置
    struct DetectionThresholds {
        // Preparation → Loading
        var kneeFlexionDecreaseThreshold: Float = 10.0  // 膝屈曲减少10度
        var preparationMinDuration: TimeInterval = 0.5  // 准备至少0.5秒
        
        // Loading → Contact
        var wristVelocityThreshold: Float = 12.0        // 手腕速度超过12 m/s
        var wristHeightThreshold: Float = 2.0           // 手腕高度超过2.0m
        
        // Contact → Follow Through
        var contactMinDuration: TimeInterval = 0.1      // 击球瞬间至少0.1秒
        var velocityDecayThreshold: Float = 0.7         // 速度衰减到峰值的70%
        
        // General
        var movementStillThreshold: Float = 1.0         // 运动速度<1 m/s视为静止
        var windowSize: Int = 10                        // 时间窗口大小(帧数)
    }
    
    var thresholds = DetectionThresholds()
    
    // MARK: - State
    
    /// 当前检测到的阶段
    private(set) var currentPhase: ServePhase = .preparation
    
    /// 阶段事件历史
    private(set) var phaseHistory: [ServePhaseEvent] = []
    
    /// 指标历史窗口 (用于时间序列分析)
    private var metricsWindow: [BiomechanicsMetrics] = []
    
    /// 当前阶段开始的指标
    private var currentPhaseStartMetrics: BiomechanicsMetrics?
    
    /// 当前阶段开始时间
    private var currentPhaseStartTime: TimeInterval?
    
    /// 峰值速度记录（用于Contact检测）
    private var peakWristVelocity: Float = 0
    
    // MARK: - Public Methods
    
    /// 处理新的生物力学指标，检测阶段转换
    /// - Parameter metrics: 当前帧的生物力学指标
    /// - Returns: 如果检测到阶段变化，返回新的阶段事件
    @discardableResult
    func processMetrics(_ metrics: BiomechanicsMetrics) -> ServePhaseEvent? {
        // 添加到历史窗口
        metricsWindow.append(metrics)
        if metricsWindow.count > thresholds.windowSize {
            metricsWindow.removeFirst()
        }
        
        // 更新峰值速度
        if let velocity = metrics.rightWristVelocity {
            peakWristVelocity = max(peakWristVelocity, velocity)
        }
        
        // 检测阶段转换
        let newPhase = detectPhaseTransition(currentMetrics: metrics)
        
        if let newPhase = newPhase, newPhase != currentPhase {
            return transitionToPhase(newPhase, metrics: metrics)
        }
        
        return nil
    }
    
    /// 重置检测器状态（开始新的发球分析）
    func reset() {
        currentPhase = .preparation
        phaseHistory = []
        metricsWindow = []
        currentPhaseStartMetrics = nil
        currentPhaseStartTime = nil
        peakWristVelocity = 0
    }
    
    /// 获取当前发球的完整序列
    func getCurrentServeSequence() -> [ServePhaseEvent] {
        return phaseHistory
    }
    
    /// 获取阶段历史
    func getPhaseHistory() -> [ServePhaseEvent] {
        return phaseHistory
    }
    
    /// 判断是否检测到完整发球（所有4个阶段）
    var hasCompleteServe: Bool {
        let detectedPhases = Set(phaseHistory.map { $0.phase })
        return detectedPhases.count == 4
    }
    
    // MARK: - Private Detection Logic
    
    private func detectPhaseTransition(currentMetrics: BiomechanicsMetrics) -> ServePhase? {
        guard metricsWindow.count >= 3 else { return nil }  // 至少需要3帧数据
        
        switch currentPhase {
        case .preparation:
            return detectLoadingStart(currentMetrics)
            
        case .loading:
            return detectContactStart(currentMetrics)
            
        case .contact:
            return detectFollowThroughStart(currentMetrics)
            
        case .followThrough:
            // 随挥结束后可以重新开始（检测新的准备阶段）
            return detectPreparationStart(currentMetrics)
        }
    }
    
    /// 检测 Preparation → Loading
    private func detectLoadingStart(_ metrics: BiomechanicsMetrics) -> ServePhase? {
        guard let currentKnee = metrics.rightKneeFlexion else { return nil }
        
        // 检查准备阶段是否持续足够时间
        if let startTime = currentPhaseStartTime,
           metrics.timestamp - startTime < thresholds.preparationMinDuration {
            return nil
        }
        
        // 检查膝屈曲是否开始减小（下蹲动作）
        let recentKnees = metricsWindow.suffix(5).compactMap { $0.rightKneeFlexion }
        if recentKnees.count >= 3 {
            let kneeDecrease = recentKnees.first! - recentKnees.last!
            if kneeDecrease > thresholds.kneeFlexionDecreaseThreshold {
                return .loading
            }
        }
        
        return nil
    }
    
    /// 检测 Loading → Contact
    private func detectContactStart(_ metrics: BiomechanicsMetrics) -> ServePhase? {
        guard let wristVelocity = metrics.rightWristVelocity,
              let wristHeight = metrics.rightWristHeight else { return nil }
        
        // 条件1: 手腕速度超过阈值
        let velocityCondition = wristVelocity > thresholds.wristVelocityThreshold
        
        // 条件2: 手腕高度达到较高位置
        let heightCondition = wristHeight > thresholds.wristHeightThreshold
        
        // 条件3: 手腕高度接近峰值（检测最近5帧）
        let recentHeights = metricsWindow.suffix(5).compactMap { $0.rightWristHeight }
        let isPeakHeight = recentHeights.count >= 3 && wristHeight >= recentHeights.max()! * 0.95
        
        if velocityCondition && heightCondition && isPeakHeight {
            return .contact
        }
        
        return nil
    }
    
    /// 检测 Contact → Follow Through
    private func detectFollowThroughStart(_ metrics: BiomechanicsMetrics) -> ServePhase? {
        // 条件1: Contact阶段持续最小时间
        if let startTime = currentPhaseStartTime,
           metrics.timestamp - startTime < thresholds.contactMinDuration {
            return nil
        }
        
        // 条件2: 手腕速度开始衰减
        guard let currentVelocity = metrics.rightWristVelocity else { return nil }
        
        let velocityDecayed = currentVelocity < peakWristVelocity * thresholds.velocityDecayThreshold
        
        // 条件3: 手腕高度开始下降
        let recentHeights = metricsWindow.suffix(5).compactMap { $0.rightWristHeight }
        let heightDecreasing = recentHeights.count >= 3 && recentHeights.first! > recentHeights.last!
        
        if velocityDecayed && heightDecreasing {
            return .followThrough
        }
        
        return nil
    }
    
    /// 检测 Follow Through → Preparation (新发球开始)
    private func detectPreparationStart(_ metrics: BiomechanicsMetrics) -> ServePhase? {
        // 条件: 身体基本静止（速度很低）
        guard let wristVelocity = metrics.rightWristVelocity else { return nil }
        
        if wristVelocity < thresholds.movementStillThreshold {
            // 检测到新发球开始，重置峰值速度
            peakWristVelocity = 0
            return .preparation
        }
        
        return nil
    }
    
    // MARK: - State Management
    
    private func transitionToPhase(_ newPhase: ServePhase, metrics: BiomechanicsMetrics) -> ServePhaseEvent {
        // 计算上一阶段的持续时间
        if let startTime = currentPhaseStartTime,
           !phaseHistory.isEmpty {
            let duration = metrics.timestamp - startTime
            phaseHistory[phaseHistory.count - 1].duration = duration
        }
        
        // 创建新的阶段事件
        let event = ServePhaseEvent(
            phase: newPhase,
            timestamp: metrics.timestamp,
            keyMetrics: metrics
        )
        
        // 更新状态
        currentPhase = newPhase
        currentPhaseStartMetrics = metrics
        currentPhaseStartTime = metrics.timestamp
        phaseHistory.append(event)
        
        print("🎯 Phase Transition: \(newPhase.emoji) \(newPhase.displayName) at \(metrics.timestamp)")
        
        return event
    }
}

// MARK: - Analysis Extensions

extension ServePhaseDetector {
    
    /// 获取发球质量分析
    func getServeQualityAnalysis() -> ServeQualityAnalysis? {
        guard hasCompleteServe else { return nil }
        
        // 提取各阶段的关键指标
        var loadingMetrics: BiomechanicsMetrics?
        var contactMetrics: BiomechanicsMetrics?
        
        for event in phaseHistory {
            switch event.phase {
            case .loading:
                loadingMetrics = event.keyMetrics
            case .contact:
                contactMetrics = event.keyMetrics
            default:
                break
            }
        }
        
        return ServeQualityAnalysis(
            loadingPhaseMetrics: loadingMetrics,
            contactPhaseMetrics: contactMetrics,
            totalDuration: phaseHistory.last!.timestamp - phaseHistory.first!.timestamp
        )
    }
}

/// 发球质量分析结果
struct ServeQualityAnalysis {
    let loadingPhaseMetrics: BiomechanicsMetrics?
    let contactPhaseMetrics: BiomechanicsMetrics?
    let totalDuration: TimeInterval
    
    /// 蓄力阶段质量评分 (0-100)
    var loadingQuality: Float {
        guard let metrics = loadingPhaseMetrics else { return 0 }
        var score: Float = 0
        var count: Float = 0
        
        if let knee = metrics.rightKneeFlexion {
            score += evaluateKnee(knee)
            count += 1
        }
        
        if let separation = metrics.hipShoulderSeparation {
            score += evaluateSeparation(separation)
            count += 1
        }
        
        return count > 0 ? score / count : 0
    }
    
    /// 击球阶段质量评分 (0-100)
    var contactQuality: Float {
        guard let metrics = contactPhaseMetrics else { return 0 }
        var score: Float = 0
        var count: Float = 0
        
        if let height = metrics.contactHeight {
            score += evaluateHeight(height)
            count += 1
        }
        
        if let velocity = metrics.rightWristVelocity {
            score += evaluateVelocity(velocity)
            count += 1
        }
        
        return count > 0 ? score / count : 0
    }
    
    /// 总体质量评分
    var overallQuality: Float {
        return (loadingQuality + contactQuality) / 2
    }
    
    // MARK: - Private Evaluation
    
    private func evaluateKnee(_ angle: Float) -> Float {
        switch angle {
        case 40...60: return 100
        case 30..<40, 60..<75: return 70
        default: return 40
        }
    }
    
    private func evaluateSeparation(_ angle: Float) -> Float {
        switch angle {
        case 30...50: return 100
        case 20..<30, 50..<60: return 70
        default: return 40
        }
    }
    
    private func evaluateHeight(_ height: Float) -> Float {
        if height >= 2.4 { return 100 }
        if height >= 2.2 { return 70 }
        return 40
    }
    
    private func evaluateVelocity(_ velocity: Float) -> Float {
        if velocity >= 15 { return 100 }
        if velocity >= 10 { return 70 }
        return 40
    }
}
