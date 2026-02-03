import Foundation
import SwiftData

/// 会话数据仓库
/// Repository for managing AnalysisSession persistence using SwiftData.
@MainActor
class SessionRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Create
    
    /// 保存新会话
    func save(_ session: AnalysisSession) throws {
        modelContext.insert(session)
        try modelContext.save()
        print("✅ Session saved: \(session.id)")
    }
    
    // MARK: - Read
    
    /// 获取最近的会话
    func fetchRecent(limit: Int = 10) throws -> [AnalysisSession] {
        let descriptor = FetchDescriptor<AnalysisSession>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        var sessions = try modelContext.fetch(descriptor)
        if sessions.count > limit {
            sessions = Array(sessions.prefix(limit))
        }
        return sessions
    }
    
    /// 根据日期范围获取会话
    func fetchByDateRange(_ range: ClosedRange<Date>) throws -> [AnalysisSession] {
        let descriptor = FetchDescriptor<AnalysisSession>(
            predicate: #Predicate { session in
                session.timestamp >= range.lowerBound &&
                session.timestamp <= range.upperBound
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取特定会话
    func fetch(by id: UUID) throws -> AnalysisSession? {
        let descriptor = FetchDescriptor<AnalysisSession>(
            predicate: #Predicate { session in
                session.id == id
            }
        )
        
        return try modelContext.fetch(descriptor).first
    }
    
    /// 获取所有会话
    func fetchAll() throws -> [AnalysisSession] {
        let descriptor = FetchDescriptor<AnalysisSession>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Update
    
    /// 更新会话
    func update(_ session: AnalysisSession) throws {
        try modelContext.save()
        print("✅ Session updated: \(session.id)")
    }
    
    // MARK: - Delete
    
    /// 删除特定会话
    func delete(_ session: AnalysisSession) throws {
        modelContext.delete(session)
        try modelContext.save()
        print("🗑️ Session deleted: \(session.id)")
    }
    
    /// 删除所有会话
    func deleteAll() throws {
        try modelContext.delete(model: AnalysisSession.self)
        try modelContext.save()
        print("🗑️ All sessions deleted")
    }
    
    // MARK: - Statistics
    
    /// 获取统计信息
    func getStatistics() throws -> SessionStatistics {
        let sessions = try fetchAll()
        
        guard !sessions.isEmpty else {
            return SessionStatistics(
                totalSessions: 0,
                totalServes: 0,
                averageQuality: 0,
                totalDuration: 0,
                improvementTrend: []
            )
        }
        
        let totalSessions = sessions.count
        let totalServes = sessions.reduce(0) { $0 + $1.servesDetected }
        let totalDuration = sessions.reduce(0.0) { $0 + $1.duration }
        let averageQuality = sessions.reduce(0.0) { $0 + $1.overallQualityScore } / Float(totalSessions)
        
        // 计算改进趋势
        let trend = calculateImprovementTrend(sessions: sessions)
        
        return SessionStatistics(
            totalSessions: totalSessions,
            totalServes: totalServes,
            averageQuality: averageQuality,
            totalDuration: totalDuration,
            improvementTrend: trend
        )
    }
    
    /// 获取最佳记录
    func getBestRecords() throws -> BestRecords {
        let sessions = try fetchAll()
        
        guard !sessions.isEmpty else {
            return BestRecords()
        }
        
        return BestRecords(
            bestQualityScore: sessions.map { $0.overallQualityScore }.max() ?? 0,
            bestKneeFlexion: sessions.compactMap { $0.bestKneeFlexion }.max(),
            bestSeparation: sessions.compactMap { $0.bestHipShoulderSeparation }.max(),
            bestHeight: sessions.compactMap { $0.bestContactHeight }.max(),
            bestVelocity: sessions.compactMap { $0.bestWristVelocity }.max()
        )
    }
    
    // MARK: - Export
    
    /// 导出会话为JSON
    func exportToJSON(_ session: AnalysisSession) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        // 创建导出数据结构
        let exportData = SessionExportData(
            id: session.id.uuidString,
            timestamp: session.timestamp,
            duration: session.duration,
            totalFrames: session.totalFrames,
            servesDetected: session.servesDetected,
            averageMetrics: [
                "kneeFlexion": session.averageKneeFlexion,
                "hipShoulderSeparation": session.averageHipShoulderSeparation,
                "contactHeight": session.averageContactHeight,
                "wristVelocity": session.averageWristVelocity
            ],
            bestMetrics: [
                "kneeFlexion": session.bestKneeFlexion,
                "hipShoulderSeparation": session.bestHipShoulderSeparation,
                "contactHeight": session.bestContactHeight,
                "wristVelocity": session.bestWristVelocity
            ],
            overallQualityScore: session.overallQualityScore,
            phaseEvents: session.phaseEvents,
            feedbackItems: session.feedbackItems,
            userHeight: session.userHeight,
            wasCalibrated: session.wasCalibrated
        )
        
        let data = try encoder.encode(exportData)
        
        // 保存到临时目录
        let filename = "apex_session_\(session.timestamp.timeIntervalSince1970).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - Helper Methods
    
    private func calculateImprovementTrend(sessions: [AnalysisSession]) -> [ImprovementPoint] {
        // 按时间排序
        let sortedSessions = sessions.sorted { $0.timestamp < $1.timestamp }
        
        // 提取质量分数趋势
        return sortedSessions.map { session in
            ImprovementPoint(
                date: session.timestamp,
                metricName: "overallQuality",
                value: session.overallQualityScore
            )
        }
    }
}

// MARK: - Supporting Types

struct SessionStatistics {
    let totalSessions: Int
    let totalServes: Int
    let averageQuality: Float
    let totalDuration: TimeInterval
    let improvementTrend: [ImprovementPoint]
    
    var formattedDuration: String {
        let minutes = Int(totalDuration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(remainingMinutes)分钟"
        } else {
            return "\(remainingMinutes)分钟"
        }
    }
}

struct BestRecords {
    var bestQualityScore: Float = 0
    var bestKneeFlexion: Float?
    var bestSeparation: Float?
    var bestHeight: Float?
    var bestVelocity: Float?
}

struct SessionExportData: Codable {
    let id: String
    let timestamp: Date
    let duration: TimeInterval
    let totalFrames: Int
    let servesDetected: Int
    let averageMetrics: [String: Float?]
    let bestMetrics: [String: Float?]
    let overallQualityScore: Float
    let phaseEvents: [ServePhaseEvent]
    let feedbackItems: [FeedbackItem]
    let userHeight: Float
    let wasCalibrated: Bool
}
