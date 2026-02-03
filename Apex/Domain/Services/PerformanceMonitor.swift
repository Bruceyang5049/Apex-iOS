import Foundation
import QuartzCore
import os.log

/// 性能监控器
/// Monitors app performance metrics like FPS, inference time, memory, and CPU usage.
@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentFPS: Double = 0
    @Published var averageInferenceTime: TimeInterval = 0
    @Published var memoryUsageMB: Float = 0
    @Published var cpuUsage: Float = 0
    @Published var isMonitoring: Bool = false
    
    // MARK: - Private State
    
    private var displayLink: CADisplayLink?
    private var frameTimestamps: [CFTimeInterval] = []
    private var inferenceTimestamps: [(start: TimeInterval, end: TimeInterval)] = []
    private var lastFrameTimestamp: CFTimeInterval = 0
    
    /// FPS采样窗口大小
    private let fpsWindowSize = 30
    
    /// 推理时间采样窗口大小
    private let inferenceWindowSize = 20
    
    /// 性能报告缓存
    private var reportHistory: [PerformanceReport] = []
    
    // MARK: - Monitoring Control
    
    /// 开始性能监控
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        frameTimestamps.removeAll()
        inferenceTimestamps.removeAll()
        
        // 启动DisplayLink用于FPS监控
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .common)
        
        // 启动内存和CPU监控（每秒更新一次）
        startResourceMonitoring()
        
        print("📊 Performance monitoring started")
    }
    
    /// 停止性能监控
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
        
        print("📊 Performance monitoring stopped")
        print("   Avg FPS: \(String(format: "%.1f", currentFPS))")
        print("   Avg Inference: \(String(format: "%.1f", averageInferenceTime * 1000))ms")
    }
    
    // MARK: - FPS Tracking
    
    @objc private func displayLinkCallback(_ displayLink: CADisplayLink) {
        let currentTimestamp = displayLink.timestamp
        
        if lastFrameTimestamp > 0 {
            frameTimestamps.append(currentTimestamp)
            
            // 保持窗口大小
            if frameTimestamps.count > fpsWindowSize {
                frameTimestamps.removeFirst()
            }
            
            // 计算FPS
            if frameTimestamps.count >= 2 {
                let duration = frameTimestamps.last! - frameTimestamps.first!
                currentFPS = Double(frameTimestamps.count - 1) / duration
            }
        }
        
        lastFrameTimestamp = currentTimestamp
    }
    
    // MARK: - Inference Time Tracking
    
    /// 记录推理开始
    func recordInferenceStart() -> TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    /// 记录推理结束并计算耗时
    func recordInferenceEnd(startTime: TimeInterval) {
        let endTime = Date().timeIntervalSince1970
        
        inferenceTimestamps.append((start: startTime, end: endTime))
        
        // 保持窗口大小
        if inferenceTimestamps.count > inferenceWindowSize {
            inferenceTimestamps.removeFirst()
        }
        
        // 计算平均推理时间
        let totalTime = inferenceTimestamps.reduce(0.0) { $0 + ($1.end - $1.start) }
        averageInferenceTime = totalTime / Double(inferenceTimestamps.count)
    }
    
    // MARK: - Resource Monitoring
    
    private func startResourceMonitoring() {
        Task {
            while isMonitoring {
                updateMemoryUsage()
                updateCPUUsage()
                
                // 每秒更新一次
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            memoryUsageMB = Float(info.resident_size) / 1024 / 1024
        }
    }
    
    private func updateCPUUsage() {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        
        let result = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        guard result == KERN_SUCCESS, let threads = threadsList else {
            return
        }
        
        for index in 0..<Int(threadsCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            
            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }
            
            if infoResult == KERN_SUCCESS {
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags != TH_FLAGS_IDLE {
                    totalUsageOfCPU += Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        
        cpuUsage = Float(totalUsageOfCPU)
    }
    
    // MARK: - Performance Report
    
    /// 获取性能报告
    func getReport() -> PerformanceReport {
        let report = PerformanceReport(
            averageFPS: currentFPS,
            minFPS: calculateMinFPS(),
            maxFPS: calculateMaxFPS(),
            frameDrops: calculateFrameDrops(),
            averageInferenceTime: averageInferenceTime,
            peakMemoryMB: memoryUsageMB,
            averageCPU: cpuUsage,
            duration: calculateMonitoringDuration()
        )
        
        reportHistory.append(report)
        return report
    }
    
    private func calculateMinFPS() -> Double {
        guard frameTimestamps.count >= 2 else { return 0 }
        
        var minFPS = Double.infinity
        
        for i in 1..<frameTimestamps.count {
            let dt = frameTimestamps[i] - frameTimestamps[i-1]
            if dt > 0 {
                let fps = 1.0 / dt
                minFPS = min(minFPS, fps)
            }
        }
        
        return minFPS == Double.infinity ? 0 : minFPS
    }
    
    private func calculateMaxFPS() -> Double {
        guard frameTimestamps.count >= 2 else { return 0 }
        
        var maxFPS = 0.0
        
        for i in 1..<frameTimestamps.count {
            let dt = frameTimestamps[i] - frameTimestamps[i-1]
            if dt > 0 {
                let fps = 1.0 / dt
                maxFPS = max(maxFPS, fps)
            }
        }
        
        return maxFPS
    }
    
    private func calculateFrameDrops() -> Int {
        guard frameTimestamps.count >= 2 else { return 0 }
        
        var drops = 0
        let targetFrameTime = 1.0 / 30.0  // 30 FPS基准
        
        for i in 1..<frameTimestamps.count {
            let dt = frameTimestamps[i] - frameTimestamps[i-1]
            if dt > targetFrameTime * 1.5 {  // 超过1.5倍认为是掉帧
                drops += 1
            }
        }
        
        return drops
    }
    
    private func calculateMonitoringDuration() -> TimeInterval {
        guard let first = frameTimestamps.first, let last = frameTimestamps.last else {
            return 0
        }
        return last - first
    }
    
    /// 重置监控数据
    func reset() {
        frameTimestamps.removeAll()
        inferenceTimestamps.removeAll()
        currentFPS = 0
        averageInferenceTime = 0
        memoryUsageMB = 0
        cpuUsage = 0
    }
}

// MARK: - Performance Report

/// 性能报告
struct PerformanceReport: Codable {
    let averageFPS: Double
    let minFPS: Double
    let maxFPS: Double
    let frameDrops: Int
    let averageInferenceTime: TimeInterval
    let peakMemoryMB: Float
    let averageCPU: Float
    let duration: TimeInterval
    let timestamp: Date
    
    init(averageFPS: Double,
         minFPS: Double,
         maxFPS: Double,
         frameDrops: Int,
         averageInferenceTime: TimeInterval,
         peakMemoryMB: Float,
         averageCPU: Float,
         duration: TimeInterval) {
        self.averageFPS = averageFPS
        self.minFPS = minFPS
        self.maxFPS = maxFPS
        self.frameDrops = frameDrops
        self.averageInferenceTime = averageInferenceTime
        self.peakMemoryMB = peakMemoryMB
        self.averageCPU = averageCPU
        self.duration = duration
        self.timestamp = Date()
    }
    
    /// 性能等级评估
    var performanceGrade: String {
        if averageFPS >= 45 && averageInferenceTime < 0.03 {
            return "优秀"
        } else if averageFPS >= 30 && averageInferenceTime < 0.05 {
            return "良好"
        } else if averageFPS >= 20 {
            return "一般"
        } else {
            return "需优化"
        }
    }
    
    /// 格式化报告
    var formattedReport: String {
        """
        📊 性能报告
        ━━━━━━━━━━━━━━━━━━━━━
        ⏱️  时长: \(String(format: "%.1f", duration))秒
        
        📹 帧率 (FPS):
           平均: \(String(format: "%.1f", averageFPS))
           最小: \(String(format: "%.1f", minFPS))
           最大: \(String(format: "%.1f", maxFPS))
           掉帧: \(frameDrops)次
        
        🤖 推理性能:
           平均耗时: \(String(format: "%.1f", averageInferenceTime * 1000))ms
        
        💾 资源占用:
           内存: \(String(format: "%.0f", peakMemoryMB))MB
           CPU: \(String(format: "%.1f", averageCPU))%
        
        🏆 综合评价: \(performanceGrade)
        ━━━━━━━━━━━━━━━━━━━━━
        """
    }
}
