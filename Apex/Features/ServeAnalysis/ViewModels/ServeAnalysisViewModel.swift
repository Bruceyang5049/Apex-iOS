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
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 是否正在分析
    @Published var isAnalyzing: Bool = false
    
    /// 校准配置
    private let biomechanicsAnalyzer: BiomechanicsAnalyzer
    private let calibrationManager: CalibrationManager
    @Published var calibrationConfig: CalibrationConfig?
    
    // MARK: - Dependencies
    
    let cameraManager: CameraManager
    private let poseEstimator: PoseEstimatorService
    
    // MARK: - Private Properties
    
    private var analysisTask: Task<Void, Never>?
    
    // MARK: - Initialization
    ,
         biomechanicsAnalyzer: BiomechanicsAnalyzer = BiomechanicsAnalyzer(),
         calibrationManager: CalibrationManager = .shared) {
        self.cameraManager = cameraManager
        self.poseEstimator = poseEstimator
        self.biomechanicsAnalyzer = biomechanicsAnalyzer
        self.calibrationManager = calibrationManager
        
        // 加载校准配置
        self.calibrationConfig = calibrationManager.loadCalibration()
        
        // 如果已校准，设置分析器的用户身高
        if let config = calibrationConfig, config.isCalibrated {
            biomechanicsAnalyzer.userHeight = config.userHeightMeters
        }ce = MediaPipePoseEstimator()) {
        self.cameraManager = cameraManager
        self.poseEstimator = poseEstimator
    }
    
    // MARK: - Public Methods
    
    /// 启动分析流程
    func startAnalysis() {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                // 1. 初始化 Pose Estimator
                try await poseEstimator.initialize()
                
                // 2. 启动相机
                try await cameraManager.startSession()
                
                // 3. 开始处理帧流
                startProcessingLoop()
                
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
        currentMetrics = nil
            } catch {
                handleError(error)
                isAnalyzing = false
            }姿势结果
                    self.currentPose = result
                    
                    // 如果检测到姿势，执行生物力学分析
                    if !result.landmarks.isEmpty {
                        let metrics = biomechanicsAnalyzer.analyze(poseResult: result)
                        self.currentMetrics = metrics
                    } else {
                        self.currentMetrics = nil
                    }
    }
    
    /// 停止分析
    func stopAnalysis() {
        isAnalyzing = false
        analysisTask?.cancel()
        analysisTask = nil
        cameraManager.stopSession()
        currentPose = nil
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
                    
                    // 执行姿势估计
                    // Perform pose estimation on the current frame.
                    let result = try await poseEstimator.process(pixelBuffer: pixelBuffer, timestamp: timestamp)
                    
                    // 更新 UI (已在 MainActor 上)
                    self.currentPose = result
                    
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
