# 生物力学模块API使用示例

## 🚀 快速开始

### 基础用法

```swift
import Foundation

// 1. 创建分析器
let analyzer = BiomechanicsAnalyzer()

// 2. 设置用户身高(可选,提高精度)
analyzer.userHeight = 1.8 // 米

// 3. 分析姿势数据
let poseResult = // ... 从MediaPipe获取
let metrics = analyzer.analyze(poseResult: poseResult)

// 4. 读取指标
if let kneeFlexion = metrics.rightKneeFlexion {
    print("右膝屈曲: \(kneeFlexion)°")
}

if let separation = metrics.hipShoulderSeparation {
    print("髋肩分离: \(separation)°")
}
```

---

## 📊 完整示例

### 示例1: 集成到现有ViewModel

```swift
import Combine

class MyAnalysisViewModel: ObservableObject {
    
    @Published var currentMetrics: BiomechanicsMetrics?
    
    private let analyzer = BiomechanicsAnalyzer()
    private let calibrationManager = CalibrationManager.shared
    
    init() {
        // 加载校准
        if let config = calibrationManager.loadCalibration() {
            analyzer.userHeight = config.userHeightMeters
        }
    }
    
    func processPoseFrame(_ poseResult: PoseEstimationResult) {
        // 分析生物力学
        let metrics = analyzer.analyze(poseResult: poseResult)
        
        // 更新UI
        DispatchQueue.main.async {
            self.currentMetrics = metrics
        }
        
        // 自定义逻辑
        if let kneeFlexion = metrics.rightKneeFlexion {
            if kneeFlexion < 40 {
                showWarning("膝盖弯曲不足!")
            }
        }
    }
    
    func updateUserHeight(_ heightCm: Float) {
        let config = CalibrationConfig(userHeightCm: heightCm)
        calibrationManager.saveCalibration(config)
        analyzer.userHeight = config.userHeightMeters
    }
}
```

### 示例2: 批量处理视频帧

```swift
func analyzeVideo(frames: [PoseEstimationResult]) -> [BiomechanicsMetrics] {
    let analyzer = BiomechanicsAnalyzer()
    analyzer.userHeight = 1.75
    
    var allMetrics: [BiomechanicsMetrics] = []
    
    for frame in frames {
        let metrics = analyzer.analyze(poseResult: frame)
        if metrics.isValid {
            allMetrics.append(metrics)
        }
    }
    
    return allMetrics
}

// 使用
let videoMetrics = analyzeVideo(frames: recordedFrames)
let avgKneeFlexion = videoMetrics.compactMap { $0.rightKneeFlexion }.average()
print("平均膝屈曲: \(avgKneeFlexion)°")
```

### 示例3: 发球质量评分

```swift
struct ServeQualityEvaluator {
    
    /// 评估发球质量 (0-100分)
    func evaluateServe(metrics: BiomechanicsMetrics) -> Float {
        var score: Float = 0
        var count: Float = 0
        
        // 膝屈曲评分 (40-60度为满分)
        if let knee = metrics.rightKneeFlexion {
            let kneeScore = evaluateKneeFlexion(knee)
            score += kneeScore
            count += 1
        }
        
        // 髋肩分离评分 (30-50度为满分)
        if let separation = metrics.hipShoulderSeparation {
            let sepScore = evaluateSeparation(separation)
            score += sepScore
            count += 1
        }
        
        // 击球高度评分 (>2.4m为满分)
        if let height = metrics.contactHeight {
            let heightScore = evaluateHeight(height)
            score += heightScore
            count += 1
        }
        
        // 拍头速度评分 (>15 m/s为满分)
        if let velocity = metrics.rightWristVelocity {
            let velocityScore = evaluateVelocity(velocity)
            score += velocityScore
            count += 1
        }
        
        return count > 0 ? score / count : 0
    }
    
    private func evaluateKneeFlexion(_ angle: Float) -> Float {
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

// 使用
let evaluator = ServeQualityEvaluator()
let score = evaluator.evaluateServe(metrics: currentMetrics)
print("发球质量: \(score)分")
```

---

## 🔧 高级用法

### 自定义滤波器参数

```swift
// 创建自定义滤波器配置
let customFilter = Point3DFilter(
    minCutoff: 0.5,      // 更强平滑
    beta: 0.01,          // 更高响应性
    derivativeCutoff: 0.5
)

// 或直接修改分析器内部滤波器(需要暴露接口)
```

### 手动校准像素到米比例

```swift
let analyzer = BiomechanicsAnalyzer()

// 如果已知球场尺寸,可手动设置比例
// 例如:用户站在底线旁,已知底线长11.89m
let measuredPixelWidth: Float = 1920
let realWorldWidth: Float = 11.89
analyzer.pixelToMeterScale = realWorldWidth / measuredPixelWidth
```

### 时间序列分析

```swift
class TimeSeriesAnalyzer {
    private var metricsHistory: [BiomechanicsMetrics] = []
    private let windowSize = 30 // 保留最近30帧
    
    func addMetrics(_ metrics: BiomechanicsMetrics) {
        metricsHistory.append(metrics)
        
        // 保持窗口大小
        if metricsHistory.count > windowSize {
            metricsHistory.removeFirst()
        }
    }
    
    func detectServePhase() -> ServePhase? {
        guard metricsHistory.count >= 10 else { return nil }
        
        // 检测蓄力阶段 (膝屈曲持续增加)
        let recentKneeAngles = metricsHistory.suffix(10).compactMap { $0.rightKneeFlexion }
        if isDecreasing(recentKneeAngles) {
            return .loading
        }
        
        // 检测击球阶段 (手腕速度峰值)
        let recentVelocities = metricsHistory.suffix(5).compactMap { $0.rightWristVelocity }
        if let maxVel = recentVelocities.max(), maxVel > 15 {
            return .contact
        }
        
        return .preparation
    }
    
    private func isDecreasing(_ values: [Float]) -> Bool {
        guard values.count > 1 else { return false }
        return values.last! < values.first!
    }
}

enum ServePhase {
    case preparation
    case loading
    case contact
    case followThrough
}
```

---

## 🎨 SwiftUI集成示例

### 实时指标卡片

```swift
struct MetricCard: View {
    let title: String
    let value: Float?
    let unit: String
    let idealRange: ClosedRange<Float>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let value = value {
                HStack {
                    Text(String(format: "%.1f", value))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                }
                .foregroundColor(statusColor)
            } else {
                Text("--")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var statusColor: Color {
        guard let value = value else { return .gray }
        return idealRange.contains(value) ? .green : .orange
    }
}

// 使用
MetricCard(
    title: "膝屈曲",
    value: metrics?.rightKneeFlexion,
    unit: "°",
    idealRange: 40...60
)
```

### 趋势图表

```swift
import Charts

struct MetricsTrendView: View {
    let history: [BiomechanicsMetrics]
    
    var body: some View {
        Chart {
            ForEach(Array(history.enumerated()), id: \.offset) { index, metrics in
                if let knee = metrics.rightKneeFlexion {
                    LineMark(
                        x: .value("Frame", index),
                        y: .value("Knee Flexion", knee)
                    )
                    .foregroundStyle(.blue)
                }
            }
            
            // 理想范围区域
            RectangleMark(
                xStart: .value("Start", 0),
                xEnd: .value("End", history.count),
                yStart: .value("Min", 40),
                yEnd: .value("Max", 60)
            )
            .foregroundStyle(.green.opacity(0.2))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 200)
    }
}
```

---

## 📤 数据导出

### 导出为JSON

```swift
extension BiomechanicsMetrics: Codable {
    // 已实现Codable协议
}

func exportMetrics(_ metrics: [BiomechanicsMetrics], to url: URL) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    do {
        let data = try encoder.encode(metrics)
        try data.write(to: url)
        print("✅ Exported \(metrics.count) metrics to \(url)")
    } catch {
        print("❌ Export failed: \(error)")
    }
}

// 使用
let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let fileURL = documentsURL.appendingPathComponent("serve_analysis.json")
exportMetrics(metricsHistory, to: fileURL)
```

### 导出为CSV

```swift
func exportToCSV(_ metrics: [BiomechanicsMetrics]) -> String {
    var csv = "Timestamp,KneeFlexion,HipShoulderSeparation,ContactHeight,WristVelocity\n"
    
    for m in metrics {
        let row = [
            String(m.timestamp),
            String(m.rightKneeFlexion ?? 0),
            String(m.hipShoulderSeparation ?? 0),
            String(m.contactHeight ?? 0),
            String(m.rightWristVelocity ?? 0)
        ].joined(separator: ",")
        
        csv += row + "\n"
    }
    
    return csv
}
```

---

## 🧩 工具函数

### Array扩展

```swift
extension Array where Element == Float {
    func average() -> Float {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Float(count)
    }
    
    func standardDeviation() -> Float {
        let avg = average()
        let variance = map { pow($0 - avg, 2) }.average()
        return sqrt(variance)
    }
}

// 使用
let kneeAngles = metricsHistory.compactMap { $0.rightKneeFlexion }
print("平均: \(kneeAngles.average())°")
print("标准差: \(kneeAngles.standardDeviation())°")
```

---

## 💡 最佳实践

1. **始终检查nil值**: 指标可能因可见度低而为nil
2. **使用isValid**: 验证指标整体有效性
3. **定期重置**: 长时间运行后重置滤波器避免累积误差
4. **校准优先**: 首次使用务必引导用户校准
5. **批量处理**: 分析录制视频时批量处理性能更好
6. **异步处理**: 在后台线程执行分析,避免阻塞UI

---

## 🔗 相关文档

- [BIOMECHANICS_IMPLEMENTATION.md](./BIOMECHANICS_IMPLEMENTATION.md) - 实现细节
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - 测试指南
- [README.md](./README.md) - 项目总览
