import Foundation
import Combine
import CoreVideo
import SwiftUI

/// 发球分析视图模型
/// ViewModel for the Serve Analysis feature.
/// Orchestrates the data flow between Camera, PoseEstimator, and UI.
@MainActor
class ServeAnalysisViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前姿势估计结果
    @Published var currentPose: PoseEstimationResult?
    
    /// 当前生物力学指标
    @Published var currentMetrics: BiomechanicsMetrics?
    
    /// 当前发球阶段
    @Published var currentPhase: ServePhase = .preparation
    
    /// 质量分析结果
    @Published var qualityAnalysis: ServeQualityAnalysis?
    
    /// AI反馈列表
    @Published var feedbackItems: [FeedbackItem] = []
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 是否正在分析
    @Published var isAnalyzing: Bool = false
    
    /// 校准配置
    @Published var calibrationConfig: CalibrationConfig?
    
    // MARK: - Dependencies
    
    let cameraManager: CameraManager
    private let poseEstimator: PoseEstimatorService
    private let biomechanicsAnalyzer: BiomechanicsAnalyzer
    private let calibrationManager: CalibrationManager
    private let phaseDetector: ServePhaseDetector
    private let feedbackGenerator: FeedbackGenerator
    private let sessionRepository: SessionRepository
    let performanceMonitor: PerformanceMonitor
    
    // MARK: - Private Properties
    
    private var analysisTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(cameraManager: CameraManager = CameraManager(),
         poseEstimator: PoseEstimatorService = MediaPipePoseEstimator(),
         biomechanicsAnalyzer: BiomechanicsAnalyzer = BiomechanicsAnalyzer(),
         calibrationManager: CalibrationManager = .shared,
         phaseDetector: ServePhaseDetector = ServePhaseDetector(),
         feedbackGenerator: FeedbackGenerator = FeedbackGenerator(),
         sessionRepository: SessionRepository,
         performanceMonitor: PerformanceMonitor = PerformanceMonitor()) {
        self.cameraManager = cameraManager
        self.poseEstimator = poseEstimator
        self.biomechanicsAnalyzer = biomechanicsAnalyzer
        self.calibrationManager = calibrationManager
        self.phaseDetector = phaseDetector
        self.feedbackGenerator = feedbackGenerator
        self.sessionRepository = sessionRepository
        self.performanceMonitor = performanceMonitor
        
        // 加载校准配置
        self.calibrationConfig = calibrationManager.loadCalibration()
        
        // 如果已校准，设置分析器的用户身高
        if let config = calibrationConfig, config.isCalibrated {
            biomechanicsAnalyzer.userHeight = config.userHeightMeters
        }
    }
    
    // MARK: - Public Methods
    
    /// 启动分析流程
    func startAnalysis() {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        errorMessage = nil
        
        // 启动性能监控
        performanceMonitor.startMonitoring()
        
        Task {
            do {
                // 1. 初始化 Pose Estimator
                try await poseEstimator.initialize()
                
                // 2. 启动相机
                try await cameraManager.startSession()
                
                // 3. 开始处理帧流
                startProcessingLoop()
                
            } catch {
                handleError(error)
                isAnalyzing = false
            }
        }
    }
    
    /// 停止分析
    func stopAnalysis() {
        // 停止性能监控
        performanceMonitor.stopMonitoring()
        
        // 保存会话
        saveSession()
        
        isAnalyzing = false
        analysisTask?.cancel()
        analysisTask = nil
        cameraManager.stopSession()
        currentPose = nil
        currentMetrics = nil
    }
    
    /// 更新校准配置
    func updateCalibration(heightCm: Float) {
        let config = CalibrationConfig(userHeightCm: heightCm)
        calibrationConfig = config
        calibrationManager.saveCalibration(config)
        biomechanicsAnalyzer.userHeight = config.userHeightMeters
        print("✅ Calibration updated: \(heightCm) cm")
    }
    
    /// 重置分析器 (清除滤波器历史)
    func resetAnalyzer() {
        biomechanicsAnalyzer.reset()
        phaseDetector.reset()
        currentMetrics = nil
        feedbackItems.removeAll()
    }
    
    /// 保存当前分析会话
    func saveSession() {
        guard let metrics = currentMetrics else { return }
        
        let session = AnalysisSession(
            videoUrl: nil,
            duration: performanceMonitor.getReport().duration,
            averageFPS: performanceMonitor.currentFPS,
            phaseEvents: phaseDetector.getPhaseHistory(),
            feedbackItems: feedbackItems,
            averageMetrics: metrics,
            bestMetrics: metrics,
            overallQualityScore: qualityAnalysis?.overallScore ?? 0
        )
        
        do {
            try sessionRepository.save(session)
            print("✅ Session saved: \(session.id)")
        } catch {
            print("❌ Failed to save session: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func startProcessingLoop() {
        analysisTask = Task {
            // 遍历相机帧流
            // Iterate over the async stream of camera frames.
            for await pixelBuffer in cameraManager.frameStream {
                if Task.isCancelled { break }
                
                do {
                    // 获取当前时间戳
                    let timestamp = Date().timeIntervalSince1970
                    
                    // 记录推理开始
                    let inferenceStart = performanceMonitor.recordInferenceStart()
                    
                    // 执行姿势估计
                    // Perform pose estimation on the current frame.
                    let result = try await poseEstimator.process(pixelBuffer: pixelBuffer, timestamp: timestamp)
                    
                    // 记录推理结束
                    performanceMonitor.recordInferenceEnd(startTime: inferenceStart)
                    
                    // 更新 UI (已在 MainActor 上)
                    self.currentPose = result
                    
                    // 如果检测到姿势，执行生物力学分析
                    if !result.landmarks.isEmpty {
                        let metrics = biomechanicsAnalyzer.analyze(poseResult: result)
                        self.currentMetrics = metrics
                        
                        // 阶段检测
                        phaseDetector.processMetrics(metrics)
                        
                        // 更新当前阶段
                        let detectedPhase = phaseDetector.currentPhase
                        if detectedPhase != currentPhase {
                            print("🎾 Phase transition: \(currentPhase) → \(detectedPhase)")
                            currentPhase = detectedPhase
                        }
                        
                        // 获取质量分析
                        qualityAnalysis = phaseDetector.getServeQualityAnalysis()
                        
                        // 生成反馈
                        if currentPhase == .followThrough {
                            feedbackItems = feedbackGenerator.generateFeedback(
                                metrics: metrics,
                                phase: currentPhase,
                                qualityAnalysis: analysis
                            )
                        }
                    } else {
                        self.currentMetrics = nil
                    }
                    
                } catch {
                    print("⚠️ Pose estimation error: \(error)")
                    // 选择性忽略单帧错误，避免中断整个流
                }
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            self.errorMessage = appError.localizedDescription
        } else {
            self.errorMessage = error.localizedDescription
        }
        print("❌ Analysis Error: \(error)")
    }
}
