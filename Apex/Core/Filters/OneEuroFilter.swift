import Foundation

/// One Euro Filter - 用于平滑噪声数据，同时保持低延迟
/// A low-pass filter with adaptive cutoff frequency based on signal velocity.
/// Reference: https://cristal.univ-lille.fr/~casiez/1euro/
///
/// 适用于实时跟踪场景，能在稳定时强力平滑，运动时快速响应。
class OneEuroFilter {
    
    // MARK: - Configuration Parameters
    
    /// 最小截止频率 (Hz) - 控制平滑强度
    /// Lower values = more smoothing, higher latency
    private let minCutoff: Double
    
    /// 速度截止频率 (Hz) - 控制对速度的响应
    private let beta: Double
    
    /// 导数截止频率 (Hz)
    private let derivativeCutoff: Double
    
    // MARK: - Internal State
    
    /// 上一次滤波的值
    private var previousFilteredValue: Double?
    
    /// 上一次计算的导数
    private var previousDerivative: Double?
    
    /// 上一次的时间戳
    private var previousTimestamp: TimeInterval?
    
    // MARK: - Initialization
    
    /// 初始化 One Euro Filter
    /// - Parameters:
    ///   - minCutoff: 最小截止频率，默认 1.0 Hz (更强的平滑)
    ///   - beta: 速度系数，默认 0.007 (对快速移动的响应性)
    ///   - derivativeCutoff: 导数截止频率，默认 1.0 Hz
    init(minCutoff: Double = 1.0,
         beta: Double = 0.007,
         derivativeCutoff: Double = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.derivativeCutoff = derivativeCutoff
    }
    
    // MARK: - Public Methods
    
    /// 对输入值进行滤波
    /// - Parameters:
    ///   - value: 当前测量值
    ///   - timestamp: 当前时间戳 (秒)
    /// - Returns: 滤波后的值
    func filter(_ value: Double, timestamp: TimeInterval) -> Double {
        // 首次调用，直接返回原值
        guard let prevTimestamp = previousTimestamp,
              let prevValue = previousFilteredValue else {
            previousFilteredValue = value
            previousTimestamp = timestamp
            previousDerivative = 0.0
            return value
        }
        
        // 计算时间间隔 (秒)
        let dt = timestamp - prevTimestamp
        guard dt > 0 else { return prevValue } // 防止时间倒流
        
        // 1. 计算导数 (速度)
        let derivative = (value - prevValue) / dt
        
        // 2. 平滑导数
        let smoothedDerivative = exponentialSmoothing(
            current: derivative,
            previous: previousDerivative ?? 0.0,
            alpha: alphaFromCutoff(derivativeCutoff, dt: dt)
        )
        
        // 3. 基于速度自适应调整截止频率
        let cutoff = minCutoff + beta * abs(smoothedDerivative)
        
        // 4. 平滑原始值
        let alpha = alphaFromCutoff(cutoff, dt: dt)
        let filteredValue = exponentialSmoothing(
            current: value,
            previous: prevValue,
            alpha: alpha
        )
        
        // 5. 更新状态
        previousFilteredValue = filteredValue
        previousDerivative = smoothedDerivative
        previousTimestamp = timestamp
        
        return filteredValue
    }
    
    /// 重置滤波器状态
    func reset() {
        previousFilteredValue = nil
        previousDerivative = nil
        previousTimestamp = nil
    }
    
    // MARK: - Private Helpers
    
    /// 指数平滑
    /// filtered = alpha * current + (1 - alpha) * previous
    private func exponentialSmoothing(current: Double, previous: Double, alpha: Double) -> Double {
        return alpha * current + (1.0 - alpha) * previous
    }
    
    /// 根据截止频率和时间间隔计算平滑系数 alpha
    /// alpha = 1 / (1 + tau / dt), where tau = 1 / (2 * pi * cutoff)
    private func alphaFromCutoff(_ cutoff: Double, dt: Double) -> Double {
        let tau = 1.0 / (2.0 * Double.pi * cutoff)
        return 1.0 / (1.0 + tau / dt)
    }
}

// MARK: - 3D Point Filter

/// 三维点平滑滤波器 (对 x, y, z 分别应用 One Euro Filter)
class Point3DFilter {
    
    private let xFilter: OneEuroFilter
    private let yFilter: OneEuroFilter
    private let zFilter: OneEuroFilter
    
    init(minCutoff: Double = 1.0,
         beta: Double = 0.007,
         derivativeCutoff: Double = 1.0) {
        self.xFilter = OneEuroFilter(minCutoff: minCutoff, beta: beta, derivativeCutoff: derivativeCutoff)
        self.yFilter = OneEuroFilter(minCutoff: minCutoff, beta: beta, derivativeCutoff: derivativeCutoff)
        self.zFilter = OneEuroFilter(minCutoff: minCutoff, beta: beta, derivativeCutoff: derivativeCutoff)
    }
    
    /// 对 3D 点进行滤波
    func filter(x: Float, y: Float, z: Float, timestamp: TimeInterval) -> (x: Float, y: Float, z: Float) {
        let filteredX = xFilter.filter(Double(x), timestamp: timestamp)
        let filteredY = yFilter.filter(Double(y), timestamp: timestamp)
        let filteredZ = zFilter.filter(Double(z), timestamp: timestamp)
        
        return (Float(filteredX), Float(filteredY), Float(filteredZ))
    }
    
    func reset() {
        xFilter.reset()
        yFilter.reset()
        zFilter.reset()
    }
}
