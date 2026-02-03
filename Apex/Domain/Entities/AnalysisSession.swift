import Foundation
import SwiftData

/// 分析会话模型 (SwiftData)
/// Represents a single serve analysis session with all metrics and feedback.
@Model
final class AnalysisSession {
    
    // MARK: - Identity
    
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    
    // MARK: - Session Metadata
    
    var duration: TimeInterval  // 会话总时长
    var totalFrames: Int        // 总帧数
    var servesDetected: Int     // 检测到的完整发球数
    
    // MARK: - Metrics Summary
    
    /// 平均生物力学指标（整个会话）
    var averageKneeFlexion: Float?
    var averageHipShoulderSeparation: Float?
    var averageContactHeight: Float?
    var averageWristVelocity: Float?
    
    /// 最佳表现
    var bestKneeFlexion: Float?
    var bestHipShoulderSeparation: Float?
    var bestContactHeight: Float?
    var bestWristVelocity: Float?
    
    /// 总体质量分数 (0-100)
    var overallQualityScore: Float
    
    // MARK: - Phase Events (Codable Storage)
    
    /// 阶段事件序列 (JSON编码存储)
    @Attribute(.externalStorage)
    var phaseEventsData: Data?
    
    var phaseEvents: [ServePhaseEvent] {
        get {
            guard let data = phaseEventsData else { return [] }
            return (try? JSONDecoder().decode([ServePhaseEvent].self, from: data)) ?? []
        }
        set {
            phaseEventsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - Feedback Items (Codable Storage)
    
    @Attribute(.externalStorage)
    var feedbackItemsData: Data?
    
    var feedbackItems: [FeedbackItem] {
        get {
            guard let data = feedbackItemsData else { return [] }
            return (try? JSONDecoder().decode([FeedbackItem].self, from: data)) ?? []
        }
        set {
            feedbackItemsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // MARK: - User Configuration
    
    var userHeight: Float           // 用户身高(厘米)
    var wasCalibrated: Bool         // 是否使用了校准
    
    // MARK: - Optional Media
    
    var videoURLString: String?  // 录制视频的URL (如果有)
    
    var videoURL: URL? {
        get {
            guard let urlString = videoURLString else { return nil }
            return URL(string: urlString)
        }
        set {
            videoURLString = newValue?.absoluteString
        }
    }
    
    // MARK: - Initialization
    
    init(timestamp: Date = Date(),
         duration: TimeInterval = 0,
         totalFrames: Int = 0,
         servesDetected: Int = 0,
         userHeight: Float,
         wasCalibrated: Bool = false) {
        self.id = UUID()
        self.timestamp = timestamp
        self.duration = duration
        self.totalFrames = totalFrames
        self.servesDetected = servesDetected
        self.userHeight = userHeight
        self.wasCalibrated = wasCalibrated
        self.overallQualityScore = 0
    }
    
    // MARK: - Computed Properties
    
    var averageFPS: Double {
        guard duration > 0 else { return 0 }
        return Double(totalFrames) / duration
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var qualityLabel: String {
        switch overallQualityScore {
        case 90...100: return "优秀"
        case 70..<90: return "良好"
        case 50..<70: return "一般"
        default: return "需改进"
        }
    }
    
    /// 阶段事件计数
    var phaseEventsCount: Int {
        phaseEvents.count
    }
    
    /// 反馈项目计数
    var feedbackItemsCount: Int {
        feedbackItems.count
    }
    
    /// 检查是否有完整的发球序列
    var hasCompleteServe: Bool {
        let phases = Set(phaseEvents.map { $0.phase })
        return phases.count == 4
    }
    
    /// 平均阶段持续时间
    var averagePhaseDuration: TimeInterval {
        guard !phaseEvents.isEmpty else { return 0 }
        let totalDuration = phaseEvents.compactMap { $0.duration }.reduce(0, +)
        return totalDuration / Double(phaseEvents.count)
    }
}

/// 用户配置模型
@Model
final class UserProfile {
    
    @Attribute(.unique) var id: UUID
    var name: String
    var heightCm: Float
    var skillLevel: String  // NTRP评级或自定义
    var createdAt: Date
    
    // 统计数据
    var totalSessions: Int
    var totalServesAnalyzed: Int
    var averageQualityScore: Float
    
    // 关联会话（通过关系查询获取，不直接存储）
    
    init(name: String = "网球爱好者",
         heightCm: Float,
         skillLevel: String = "中级") {
        self.id = UUID()
        self.name = name
        self.heightCm = heightCm
        self.skillLevel = skillLevel
        self.createdAt = Date()
        self.totalSessions = 0
        self.totalServesAnalyzed = 0
        self.averageQualityScore = 0
    }
}

/// 改进趋势点
struct ImprovementPoint: Codable {
    let date: Date
    let metricName: String
    let value: Float
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
