import Foundation

/// 反馈严重程度
enum FeedbackSeverity: String, Codable {
    case excellent  // 优秀 🟢
    case good       // 良好 🟢
    case warning    // 需注意 ⚠️
    case critical   // 需改进 🔴
    
    var emoji: String {
        switch self {
        case .excellent, .good: return "✅"
        case .warning: return "⚠️"
        case .critical: return "❌"
        }
    }
    
    var color: String {
        switch self {
        case .excellent, .good: return "green"
        case .warning: return "yellow"
        case .critical: return "red"
        }
    }
}

/// 反馈类别
enum FeedbackCategory: String, Codable {
    case kneeFlexion        // 膝屈曲
    case hipShoulderSeparation  // 髋肩分离
    case contactHeight      // 击球高度
    case wristVelocity      // 手腕速度
    case elbowAngle         // 肘关节角度
    case bodyRotation       // 身体旋转
    case timing             // 发力时机
    case overall            // 总体评价
    
    var displayName: String {
        switch self {
        case .kneeFlexion: return "膝屈曲"
        case .hipShoulderSeparation: return "髋肩分离"
        case .contactHeight: return "击球高度"
        case .wristVelocity: return "拍头速度"
        case .elbowAngle: return "肘关节"
        case .bodyRotation: return "身体旋转"
        case .timing: return "发力时机"
        case .overall: return "总体"
        }
    }
}

/// 反馈项
struct FeedbackItem: Identifiable, Codable {
    let id: UUID
    let severity: FeedbackSeverity
    let category: FeedbackCategory
    let message: String
    let actionable: String  // 具体改进建议
    let impact: String?     // 预期效果
    let currentValue: Float?  // 当前值
    let idealRange: String?   // 理想范围
    let timestamp: TimeInterval
    
    init(severity: FeedbackSeverity,
         category: FeedbackCategory,
         message: String,
         actionable: String,
         impact: String? = nil,
         currentValue: Float? = nil,
         idealRange: String? = nil,
         timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.id = UUID()
        self.severity = severity
        self.category = category
        self.message = message
        self.actionable = actionable
        self.impact = impact
        self.currentValue = currentValue
        self.idealRange = idealRange
        self.timestamp = timestamp
    }
}

/// AI反馈生成器
/// Generates natural language coaching feedback based on biomechanics metrics.
class FeedbackGenerator {
    
    // MARK: - Elite Reference Data
    
    /// 精英选手参考数据
    struct EliteReference {
        static let kneeFlexionRange: ClosedRange<Float> = 40...60
        static let hipShoulderSeparationRange: ClosedRange<Float> = 30...50
        static let contactHeightMin: Float = 2.4  // 基于1.8m身高
        static let wristVelocityMin: Float = 15.0
        static let elbowAngleRange: ClosedRange<Float> = 90...150
    }
    
    // MARK: - Public Methods
    
    /// 生成基于单帧指标的反馈
    func generate(from metrics: BiomechanicsMetrics, phase: ServePhase? = nil) -> [FeedbackItem] {
        var feedback: [FeedbackItem] = []
        
        // 膝屈曲反馈
        if let knee = metrics.rightKneeFlexion {
            feedback.append(generateKneeFeedback(knee, phase: phase))
        }
        
        // 髋肩分离反馈
        if let separation = metrics.hipShoulderSeparation {
            feedback.append(generateSeparationFeedback(separation, phase: phase))
        }
        
        // 击球高度反馈
        if let height = metrics.contactHeight {
            feedback.append(generateHeightFeedback(height, phase: phase))
        }
        
        // 手腕速度反馈
        if let velocity = metrics.rightWristVelocity {
            feedback.append(generateVelocityFeedback(velocity, phase: phase))
        }
        
        return feedback
    }
    
    /// 生成基于完整发球序列的反馈
    func generate(from analysis: ServeQualityAnalysis) -> [FeedbackItem] {
        var feedback: [FeedbackItem] = []
        
        // 蓄力阶段反馈
        if let loadingMetrics = analysis.loadingPhaseMetrics {
            feedback.append(contentsOf: generate(from: loadingMetrics, phase: .loading))
        }
        
        // 击球阶段反馈
        if let contactMetrics = analysis.contactPhaseMetrics {
            feedback.append(contentsOf: generate(from: contactMetrics, phase: .contact))
        }
        
        // 总体评价
        feedback.append(generateOverallFeedback(analysis))
        
        return feedback
    }
    
    // MARK: - Specific Feedback Generators
    
    private func generateKneeFeedback(_ angle: Float, phase: ServePhase?) -> FeedbackItem {
        let phasePrefix = phase?.displayName ?? ""
        
        switch angle {
        case 50...60:
            return FeedbackItem(
                severity: .excellent,
                category: .kneeFlexion,
                message: "\(phasePrefix)膝屈曲度优秀 (\(Int(angle))°)",
                actionable: "保持这个深度，你的蓄力姿势已达专业水准！",
                impact: "为发球提供强大的向上爆发力",
                currentValue: angle,
                idealRange: "40-60°"
            )
            
        case 40..<50:
            return FeedbackItem(
                severity: .good,
                category: .kneeFlexion,
                message: "\(phasePrefix)膝屈曲度良好 (\(Int(angle))°)",
                actionable: "可以尝试稍微再深蹲一点，增加蓄力深度",
                impact: "能进一步提升5-10%的发球速度",
                currentValue: angle,
                idealRange: "40-60°"
            )
            
        case 30..<40:
            return FeedbackItem(
                severity: .warning,
                category: .kneeFlexion,
                message: "\(phasePrefix)膝屈曲不足 (\(Int(angle))°)",
                actionable: "建议: 下蹲时膝盖弯曲至40-60度，像压缩弹簧一样蓄力",
                impact: "改进后发球速度可提升15-20%",
                currentValue: angle,
                idealRange: "40-60°"
            )
            
        default:
            return FeedbackItem(
                severity: .critical,
                category: .kneeFlexion,
                message: "\(phasePrefix)膝屈曲严重不足 (\(Int(angle))°)",
                actionable: "重点改进: 大幅增加下蹲深度！想象坐在椅子上，膝盖弯曲40度以上",
                impact: "这是发球力量的关键来源，改进后速度可提升30%以上",
                currentValue: angle,
                idealRange: "40-60°"
            )
        }
    }
    
    private func generateSeparationFeedback(_ separation: Float, phase: ServePhase?) -> FeedbackItem {
        let phasePrefix = phase?.displayName ?? ""
        
        switch separation {
        case 40...50:
            return FeedbackItem(
                severity: .excellent,
                category: .hipShoulderSeparation,
                message: "\(phasePrefix)髋肩分离度完美 (\(Int(separation))°)",
                actionable: "太棒了！你的身体旋转技术已达职业水准，继续保持！",
                impact: "发力链协调性极佳，力量传递高效",
                currentValue: separation,
                idealRange: "30-50°"
            )
            
        case 30..<40:
            return FeedbackItem(
                severity: .good,
                category: .hipShoulderSeparation,
                message: "\(phasePrefix)髋肩分离度良好 (\(Int(separation))°)",
                actionable: "保持这个旋转幅度，或可以尝试更大的转体动作",
                impact: "良好的发力序列，继续练习可达到顶尖水平",
                currentValue: separation,
                idealRange: "30-50°"
            )
            
        case 20..<30:
            return FeedbackItem(
                severity: .warning,
                category: .hipShoulderSeparation,
                message: "\(phasePrefix)髋肩分离不足 (\(Int(separation))°)",
                actionable: "建议: 击球前先转髋，然后肩部旋转，像拧毛巾一样",
                impact: "改进后能更好地利用身体旋转产生力量",
                currentValue: separation,
                idealRange: "30-50°"
            )
            
        default:
            return FeedbackItem(
                severity: .critical,
                category: .hipShoulderSeparation,
                message: "\(phasePrefix)髋肩分离过小 (\(Int(separation))°)",
                actionable: "重点改进: 加大髋部和肩部的旋转差异！先转髋，延迟肩部旋转",
                impact: "这是发力链的核心，改进后力量可提升显著",
                currentValue: separation,
                idealRange: "30-50°"
            )
        }
    }
    
    private func generateHeightFeedback(_ height: Float, phase: ServePhase?) -> FeedbackItem {
        let phasePrefix = phase?.displayName ?? ""
        
        if height >= 2.5 {
            return FeedbackItem(
                severity: .excellent,
                category: .contactHeight,
                message: "\(phasePrefix)击球高度极佳 (\(String(format: "%.2f", height))m)",
                actionable: "完美的击球点！高度优势明显，保持住！",
                impact: "高击球点让你的发球角度更陡，过网裕度更大",
                currentValue: height,
                idealRange: ">2.4m"
            )
        } else if height >= 2.4 {
            return FeedbackItem(
                severity: .good,
                category: .contactHeight,
                message: "\(phasePrefix)击球高度良好 (\(String(format: "%.2f", height))m)",
                actionable: "击球点已经很高了，继续保持向上伸展的感觉",
                impact: "良好的过网裕度和下压角度",
                currentValue: height,
                idealRange: ">2.4m"
            )
        } else if height >= 2.2 {
            return FeedbackItem(
                severity: .warning,
                category: .contactHeight,
                message: "\(phasePrefix)击球点稍低 (\(String(format: "%.2f", height))m)",
                actionable: "建议: 击球时再向上伸展10-20cm，充分利用身高优势",
                impact: "提高击球点能增加过网裕度，减少下网失误",
                currentValue: height,
                idealRange: ">2.4m"
            )
        } else {
            return FeedbackItem(
                severity: .critical,
                category: .contactHeight,
                message: "\(phasePrefix)击球点过低 (\(String(format: "%.2f", height))m)",
                actionable: "重点改进: 大幅提高击球点！向上跳跃并完全伸展手臂",
                impact: "低击球点会导致频繁下网，提高后成功率显著提升",
                currentValue: height,
                idealRange: ">2.4m"
            )
        }
    }
    
    private func generateVelocityFeedback(_ velocity: Float, phase: ServePhase?) -> FeedbackItem {
        let phasePrefix = phase?.displayName ?? ""
        
        if velocity >= 20 {
            return FeedbackItem(
                severity: .excellent,
                category: .wristVelocity,
                message: "\(phasePrefix)拍头速度极快 (\(String(format: "%.1f", velocity)) m/s)",
                actionable: "惊人的速度！你的挥拍技术已达顶尖水准！",
                impact: "预估发球速度超过180 km/h",
                currentValue: velocity,
                idealRange: ">15 m/s"
            )
        } else if velocity >= 15 {
            return FeedbackItem(
                severity: .good,
                category: .wristVelocity,
                message: "\(phasePrefix)拍头速度良好 (\(String(format: "%.1f", velocity)) m/s)",
                actionable: "速度不错！可以继续练习爆发力和鞭打动作",
                impact: "预估发球速度150-180 km/h",
                currentValue: velocity,
                idealRange: ">15 m/s"
            )
        } else if velocity >= 10 {
            return FeedbackItem(
                severity: .warning,
                category: .wristVelocity,
                message: "\(phasePrefix)拍头速度偏慢 (\(String(format: "%.1f", velocity)) m/s)",
                actionable: "建议: 加快挥拍速度，像鞭打一样快速甩动手腕",
                impact: "提高速度后发球威胁性会明显增强",
                currentValue: velocity,
                idealRange: ">15 m/s"
            )
        } else {
            return FeedbackItem(
                severity: .critical,
                category: .wristVelocity,
                message: "\(phasePrefix)拍头速度太慢 (\(String(format: "%.1f", velocity)) m/s)",
                actionable: "重点改进: 大幅提升挥拍速度！利用全身力量传递到手腕",
                impact: "速度是发球威力的关键，改进后威胁性倍增",
                currentValue: velocity,
                idealRange: ">15 m/s"
            )
        }
    }
    
    private func generateOverallFeedback(_ analysis: ServeQualityAnalysis) -> FeedbackItem {
        let overallScore = analysis.overallQuality
        
        if overallScore >= 90 {
            return FeedbackItem(
                severity: .excellent,
                category: .overall,
                message: "本次发球质量: 优秀 (\(Int(overallScore))分)",
                actionable: "太棒了！这是一记接近完美的发球，继续保持这个水准！",
                impact: "你的技术已达到高水平业余选手标准",
                currentValue: overallScore,
                idealRange: "90-100分"
            )
        } else if overallScore >= 70 {
            return FeedbackItem(
                severity: .good,
                category: .overall,
                message: "本次发球质量: 良好 (\(Int(overallScore))分)",
                actionable: "整体表现不错，继续练习可以达到更高水平",
                impact: "在某些细节上再提升就能达到优秀水准",
                currentValue: overallScore,
                idealRange: "70-100分"
            )
        } else if overallScore >= 50 {
            return FeedbackItem(
                severity: .warning,
                category: .overall,
                message: "本次发球质量: 需改进 (\(Int(overallScore))分)",
                actionable: "关注上面标记为⚠️和❌的项目，针对性练习",
                impact: "改进关键指标后，发球质量能显著提升",
                currentValue: overallScore,
                idealRange: "70-100分"
            )
        } else {
            return FeedbackItem(
                severity: .critical,
                category: .overall,
                message: "本次发球质量: 需要大幅改进 (\(Int(overallScore))分)",
                actionable: "建议: 从基础动作开始，逐步改善膝屈曲、身体旋转等核心要素",
                impact: "耐心练习，每个细节的改进都会带来进步",
                currentValue: overallScore,
                idealRange: "70-100分"
            )
        }
    }
}

// MARK: - Feedback Formatting Extension

extension FeedbackItem {
    
    /// 格式化为用户友好的文本
    var formattedMessage: String {
        var text = "\(severity.emoji) **\(category.displayName)**: \(message)\n"
        text += "💡 \(actionable)"
        
        if let impact = impact {
            text += "\n📈 \(impact)"
        }
        
        if let value = currentValue, let range = idealRange {
            text += "\n📊 当前: \(String(format: "%.1f", value)) | 理想: \(range)"
        }
        
        return text
    }
    
    /// 简短版本（用于通知）
    var shortMessage: String {
        return "\(severity.emoji) \(category.displayName): \(message)"
    }
}
