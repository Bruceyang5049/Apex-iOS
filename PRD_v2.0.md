# APEX: AI 网球性能提升应用 PRD v2.0

> **版本历史**  
> v1.0 (2026-01) - 初始MVP规划  
> v2.0 (2026-02) - 生物力学模块实现完成，新增阶段检测与反馈系统

---

## 📋 更新概览

### v2.0 新增功能
- ✅ **完整生物力学计算引擎** - 实时计算7个核心指标
- ✅ **One Euro Filter平滑系统** - 消除噪声，保持响应性
- ✅ **用户身高校准** - 精确的像素到米转换
- ✅ **智能状态评估UI** - 颜色编码反馈（绿/黄/红）
- 🚧 **发球阶段检测** - 自动识别准备/蓄力/击球/随挥阶段
- 🚧 **AI反馈生成** - 基于指标的自然语言教练建议
- 🚧 **数据持久化** - 会话历史与进度追踪
- 🚧 **性能监控** - 帧率和性能指标仪表板

---

## 1. 产品定位 (Product Positioning)

| 字段 | 描述 |
| :--- | :--- |
| **产品名称** | APEX - AI Tennis Performance Analyzer |
| **版本** | v2.0 (MVP + Enhanced Analytics) |
| **核心价值** | 将专业教练级别的生物力学分析能力民主化，让每位网球爱好者都能获得实时、数据驱动的技术改进建议 |
| **目标用户** | 中高级业余网球爱好者 (NTRP 3.0-5.0)，追求技术提升但缺乏专业教练资源 |
| **差异化优势** | 完全设备端处理、实时反馈、精英标准对比、自然语言指导 |
| **开发理念** | Vibe Coding - AI辅助的高速迭代开发 |

---

## 2. 技术架构 (Technical Architecture)

### 2.1 核心技术栈

| 技术领域 | 解决方案 | 实现状态 |
| :--- | :--- | :--- |
| **姿势估计** | MediaPipe Pose (BlazePose) 33关键点3D世界坐标 | ✅ 已实现 |
| **数据平滑** | One Euro Filter 自适应滤波 | ✅ 已实现 |
| **生物力学计算** | 3D向量几何、角度与速度计算 | ✅ 已实现 |
| **校准系统** | 基于身高的像素-米转换 | ✅ 已实现 |
| **阶段检测** | 时间序列状态机 + 特征阈值 | 🚧 v2.0实现 |
| **反馈生成** | 规则引擎 + LLM增强 | 🚧 v2.0实现 |
| **数据持久化** | SwiftData (iOS 17+) / CoreData (兼容) | 🚧 v2.0实现 |
| **性能监控** | CADisplayLink帧率追踪 + Instruments集成 | 🚧 v2.0实现 |
| **球轨迹追踪** | TrackNet + Kalman Filter | 📅 v3.0计划 |

### 2.2 架构模式

```
┌─────────────────────────────────────────────────┐
│              Presentation Layer                  │
│  SwiftUI Views + ViewModels (MVVM)              │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│               Domain Layer                       │
│  - BiomechanicsAnalyzer (核心引擎)              │
│  - ServePhaseDetector (阶段识别) 🆕             │
│  - FeedbackGenerator (反馈生成) 🆕              │
│  - PerformanceMonitor (性能监控) 🆕             │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│                Data Layer                        │
│  - MediaPipePoseEstimator (AI推理)              │
│  - SessionRepository (数据持久化) 🆕            │
│  - CalibrationManager (校准管理)                │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│            Infrastructure Layer                  │
│  - CameraManager (视频采集)                     │
│  - OneEuroFilter (数据平滑)                     │
│  - SwiftData Store (本地数据库) 🆕              │
└─────────────────────────────────────────────────┘
```

---

## 3. 功能规格 (Feature Specifications)

### 3.1 已实现功能 (v1.5)

#### ✅ 实时姿势追踪
- 33个3D关键点检测 (MediaPipe Pose)
- 60 FPS视频处理能力
- 骨架可视化覆盖层
- 可见性与置信度评估

#### ✅ 生物力学指标计算
| 指标 | 计算方法 | 理想范围 | 用途 |
|------|---------|---------|------|
| 左/右膝屈曲角度 | 髋-膝-踝三点角度 | 40-60° | 蓄力深度评估 |
| 髋肩分离度 | 肩旋转 - 髋旋转 | 30-50° | 发力链效率 |
| 击球接触高度 | 手腕y坐标 × 校准比例 | >2.4m | 发球优势位置 |
| 手腕速度 | 帧间位移 / 时间差 | >15 m/s | 拍头速度代理 |
| 肘关节角度 | 肩-肘-腕三点角度 | 90-150° | 击球姿势 |
| 躯干旋转 | 肩/髋相对水平面角度 | - | 身体协调性 |

#### ✅ 数据平滑系统
- One Euro Filter对33个关键点独立滤波
- 自适应截止频率 (minCutoff=1.0, beta=0.007)
- 静止时强力平滑，运动时快速响应
- 重置功能清除滤波历史

#### ✅ 校准系统
- 用户身高输入 (厘米/英尺英寸)
- 基于躯干长度自动校准
- UserDefaults持久化
- 校准状态UI指示器

#### ✅ 实时UI反馈
- 指标卡片网格布局
- 颜色编码状态 (绿🟢/黄⚠️/红🔴)
- 精英参考范围对比
- 校准提示界面

---

### 3.2 v2.0 新增功能

#### 🚧 发球阶段检测系统

**目标**: 自动识别发球的4个关键阶段，实现阶段特定的分析和反馈。

**技术方案**:
```swift
enum ServePhase {
    case preparation      // 准备期: 静止站位
    case loading          // 蓄力期: 屈膝下蹲，后引拍
    case contact          // 击球期: 最高点接触球
    case followThrough    // 随挥期: 击球后动作完成
}
```

**检测规则**:
| 阶段 | 触发条件 | 关键指标 |
|------|---------|---------|
| Preparation | 身体相对静止，手腕高度稳定 | 速度 < 1 m/s，持续1秒 |
| Loading | 膝屈曲角度持续减小 | 右膝 45° → 30°，髋肩分离开始增大 |
| Contact | 手腕速度峰值 + 手腕高度峰值 | 速度 > 15 m/s 且 高度 > 2.0m |
| Follow Through | 击球后0.5-1秒 | 手腕高度下降，速度衰减 |

**数据结构**:
```swift
struct ServePhaseEvent {
    let phase: ServePhase
    let timestamp: TimeInterval
    let keyMetrics: BiomechanicsMetrics
    let duration: TimeInterval?  // 阶段持续时间
}
```

**应用场景**:
- 阶段特定的反馈 (如"蓄力阶段膝盖弯曲不足")
- 发力序列计时分析 (Kinetic Chain Timing)
- 自动截取发球片段用于回放

---

#### 🚧 AI反馈生成系统

**目标**: 将生物力学指标转换为自然、可操作的教练建议。

**反馈框架**:
```
[问题识别] + [具体数据] + [改进建议] + [鼓励语]
```

**示例输出**:
```
❌ 膝盖弯曲不足 (30°)
建议: 尝试更深的下蹲至40-60度，获得更强的向上爆发力
💪 调整后你的发球速度能提升15%！

✅ 髋肩分离度优秀 (45°)
保持: 你的身体旋转技术已达专业水准，继续保持！

⚠️ 击球点稍低 (2.2m)
建议: 击球时再向上伸展10cm，提高过网裕度
```

**技术实现**:

**阶段1: 规则引擎 (v2.0)**
```swift
class FeedbackGenerator {
    func generate(metrics: BiomechanicsMetrics, phase: ServePhase?) -> [FeedbackItem]
}

struct FeedbackItem {
    let severity: Severity      // .good, .warning, .critical
    let category: Category      // .kneeFlexion, .separation, etc.
    let message: String
    let actionable: String      // 具体改进建议
    let impact: String?         // 预期效果
}
```

**阶段2: LLM增强 (v2.5计划)**
- 集成本地CoreML语言模型 或 云端API
- 个性化风格调整
- 历史趋势分析

**精英参考数据库**:
| 指标 | 职业选手均值 | 业余标准 | 来源 |
|------|------------|---------|------|
| 膝屈曲 | 50-60° | 40-55° | ITF Biomechanics Study |
| 髋肩分离 | 40-55° | 30-45° | Tennis Analytics |
| 击球高度 | 2.5-2.8m | 2.2-2.5m | 基于身高1.75-1.85m |
| 拍头速度 | 20-25 m/s | 12-18 m/s | Hawk-Eye数据 |

---

#### 🚧 数据持久化系统

**目标**: 保存分析会话，支持历史回顾和进度追踪。

**数据模型 (SwiftData)**:
```swift
@Model
class AnalysisSession {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var duration: TimeInterval
    var totalFrames: Int
    var averageMetrics: BiomechanicsMetrics
    var phaseEvents: [ServePhaseEvent]
    var feedbackItems: [FeedbackItem]
    var videoURL: URL?  // 可选：保存录制视频
    
    // 关联用户配置
    var userHeight: Float
    var calibrationUsed: Bool
}

@Model
class UserProfile {
    var name: String
    var heightCm: Float
    var skillLevel: String  // NTRP评级
    var sessions: [AnalysisSession]
    
    // 统计数据
    var totalSessions: Int
    var averageScore: Float
    var improvementTrend: [ImprovementPoint]
}

struct ImprovementPoint: Codable {
    let date: Date
    let metric: String
    let value: Float
}
```

**功能**:
- 会话自动保存
- 历史会话列表
- 指标趋势图表 (Charts框架)
- 最佳表现记录
- 导出分析报告 (PDF/JSON)

**数据管理**:
```swift
class SessionRepository {
    func save(_ session: AnalysisSession)
    func fetchRecent(limit: Int) -> [AnalysisSession]
    func fetchByDateRange(_ range: ClosedRange<Date>) -> [AnalysisSession]
    func delete(_ session: AnalysisSession)
    func exportToJSON(_ session: AnalysisSession) -> URL
}
```

---

#### 🚧 性能监控系统

**目标**: 实时监控应用性能，确保60 FPS目标并优化资源占用。

**监控指标**:
| 指标 | 目标值 | 采样方式 |
|------|-------|---------|
| 帧率 (FPS) | ≥30, 理想60 | CADisplayLink |
| 姿势推理延迟 | <50ms | 时间戳差值 |
| CPU占用率 | <50% | ProcessInfo |
| 内存占用 | <200MB | os_proc_available_memory |
| 电池消耗 | 中等 | Energy Impact (Xcode) |
| 热节流 | 无 | thermalState监控 |

**实现**:
```swift
class PerformanceMonitor: ObservableObject {
    @Published var currentFPS: Double = 0
    @Published var averageInferenceTime: TimeInterval = 0
    @Published var memoryUsageMB: Float = 0
    @Published var cpuUsage: Float = 0
    
    private var displayLink: CADisplayLink?
    private var frameTimestamps: [CFTimeInterval] = []
    
    func startMonitoring()
    func stopMonitoring()
    func getReport() -> PerformanceReport
}

struct PerformanceReport {
    let averageFPS: Double
    let minFPS: Double
    let maxFPS: Double
    let frameDrops: Int
    let averageInferenceTime: TimeInterval
    let peakMemoryMB: Float
    let duration: TimeInterval
}
```

**优化策略**:
- 自适应帧跳跃 (低性能设备每2-3帧处理一次)
- 后台任务优先级管理
- 内存缓存池
- 模型量化 (Float16)
- 异步处理优化

**调试UI**:
```swift
struct PerformanceOverlayView: View {
    @ObservedObject var monitor: PerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("FPS: \(monitor.currentFPS, specifier: "%.1f")")
            Text("Inference: \(monitor.averageInferenceTime * 1000, specifier: "%.1f")ms")
            Text("Memory: \(monitor.memoryUsageMB, specifier: "%.0f")MB")
            Text("CPU: \(monitor.cpuUsage, specifier: "%.0f")%")
        }
        .font(.system(.caption, design: .monospaced))
        .padding(8)
        .background(.black.opacity(0.7))
        .foregroundColor(.green)
        .cornerRadius(8)
    }
}
```

---

## 4. 用户体验流程 (User Flow)

### 4.1 首次使用
```
启动应用 → 权限请求(相机) → 校准引导(身高输入) 
  → 教程(如何站位) → 开始分析 → 实时反馈 → 会话保存
```

### 4.2 日常使用
```
打开应用 → 选择模式(实时/录制) → 开始分析 
  → 查看实时指标 → 接收阶段反馈 → 结束并保存 
  → 查看会话总结 → 对比历史数据
```

### 4.3 数据回顾
```
历史记录 → 选择会话 → 查看详细指标 → 趋势图表 
  → 导出报告 → 分享(可选)
```

---

## 5. 性能与质量标准

### 5.1 性能指标
- ✅ 姿势检测准确率: >95% (可见度>0.5的关键点)
- ✅ 角度计算误差: <10°
- 🎯 帧率: ≥30 FPS (目标60 FPS)
- 🎯 端到端延迟: <150ms (相机→显示)
- 🎯 冷启动时间: <3秒
- 🎯 内存占用: <200MB

### 5.2 质量标准
- 反馈准确性: 与专业教练评价一致性>80%
- UI响应性: 无明显卡顿或跳帧
- 数据安全: 所有处理设备端，无云端上传
- 电池影响: 30分钟使用<20%电量
- 稳定性: 连续运行30分钟无崩溃

---

## 6. 开发路线图

### ✅ v1.0 - MVP基础 (2026-01)
- 姿势估计集成
- 基础UI框架
- 相机管理

### ✅ v1.5 - 生物力学模块 (2026-02-03)
- BiomechanicsAnalyzer
- One Euro Filter
- 校准系统
- 实时指标UI

### 🚧 v2.0 - 智能分析 (2026-02-10 目标)
- 发球阶段检测
- AI反馈生成
- 数据持久化
- 性能监控

### 📅 v2.5 - 增强体验 (2026-03)
- LLM集成(本地/云端)
- 视频录制与回放
- 对比分析(自己 vs 精英)
- 社交分享

### 📅 v3.0 - 球轨迹追踪 (2026-Q2)
- TrackNet模型集成
- Kalman滤波器
- 落点分析
- 旋转识别

### 📅 v4.0 - 多击球类型 (2026-Q3)
- 正手/反手分析
- 截击与高压球
- 完整比赛分析

---

## 7. 技术债务与已知限制

### 当前限制
- ❗ 仅支持单人检测 (numPoses=1)
- ❗ 需要良好光线和全身可见
- ❗ 无球轨迹追踪 (v3.0计划)
- ❗ 仅支持iOS 15+设备
- ❗ 需要真机测试 (模拟器无相机)

### 技术债务
- ⚠️ 未实现单元测试覆盖
- ⚠️ 错误处理需加强
- ⚠️ 无网络同步功能
- ⚠️ 未做国际化(仅中文)

### 优化方向
- 📈 模型量化(Float16)
- 📈 多线程优化
- 📈 内存池管理
- 📈 自适应帧率

---

## 8. 成功指标 (KPI)

### 技术指标
- 帧率稳定性: 95%时间≥30 FPS
- 崩溃率: <0.1%
- 指标计算准确率: >90% vs 真实测量
- 用户留存率: 7天>40%

### 业务指标
- 单次使用时长: >10分钟
- 周活跃用户: 目标100+ (内测阶段)
- 反馈评分: >4.5/5.0
- 分享率: >20%

---

## 9. 参考文献

1. ITF Tennis Biomechanics Research
2. MediaPipe Solutions Documentation
3. One Euro Filter - Casiez et al.
4. Tennis Analytics Database
5. NTRP Rating System Guidelines

---

**文档维护**  
最后更新: 2026-02-03  
负责人: AI Development Team  
状态: Active Development
