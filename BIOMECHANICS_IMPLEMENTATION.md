# 生物力学计算模块实现总结

## ✅ 已完成功能

### 1. **核心实体与数据模型**

#### `BiomechanicsMetrics.swift`
定义了完整的生物力学指标数据结构:
- **关节角度**: 左右膝关节、左右肘关节
- **躯干旋转**: 肩部旋转、髋部旋转、髋肩分离度
- **位置高度**: 击球高度、手腕高度
- **速度指标**: 左右手腕速度(拍头速度代理)
- **MediaPipe关键点索引常量** (33个关键点的枚举)

### 2. **数据平滑与滤波**

#### `OneEuroFilter.swift`
实现了PRD要求的One Euro Filter:
- **自适应截止频率**: 静止时强力平滑,运动时快速响应
- **低延迟设计**: 适合实时姿势追踪场景
- **3D点滤波器**: `Point3DFilter`对x/y/z坐标分别滤波
- **可配置参数**:
  - `minCutoff`: 最小截止频率(默认1.0 Hz)
  - `beta`: 速度响应系数(默认0.007)
  - `derivativeCutoff`: 导数截止频率(默认1.0 Hz)

### 3. **生物力学分析引擎**

#### `BiomechanicsAnalyzer.swift`
核心分析逻辑:

**关节角度计算**:
- `calculateKneeFlexion()`: 膝关节屈曲角度(髋-膝-踝)
- `calculateElbowAngle()`: 肘关节角度(肩-肘-腕)
- `calculateShoulderRotation()`: 肩部相对水平面旋转
- `calculateHipRotation()`: 髋部旋转
- 自动计算**髋肩分离度** (发球核心指标)

**高度与距离测量**:
- 使用MediaPipe World Landmarks(米制单位)
- 支持基于用户身高的自动校准
- 躯干长度作为参考基准(约占身高30%)

**速度计算**:
- 基于帧间位移计算3D速度
- 应用校准比例转换为实际m/s
- 右手腕速度作为拍头速度代理

**数据平滑**:
- 对33个关键点应用独立的One Euro Filter
- 消除视觉噪声和抖动
- 保持运动轨迹的连续性

### 4. **校准系统**

#### `CalibrationManager.swift`
用户身高校准管理:
- `CalibrationConfig`: 存储用户身高(厘米/米)
- 持久化到`UserDefaults`
- 支持厘米和英尺/英寸双单位系统

#### `CalibrationView.swift`
校准界面:
- 厘米/英尺英寸单位切换
- 输入验证(身高范围检查)
- 保存/跳过选项
- 加载已有校准数据

### 5. **实时指标显示**

#### `MetricsOverlayView.swift`
生物力学数据可视化:
- 网格布局显示多个指标
- **智能状态评估**:
  - 膝关节屈曲: 理想40-60° (绿色🟢)
  - 髋肩分离: 理想30-50° (绿色🟢)
  - 击球高度: 理想>2.4m (绿色🟢)
  - 手腕速度: 理想>15 m/s (绿色🟢)
- 颜色编码: 绿色(良好)/黄色(警告)/红色(需改进)
- 未校准提示界面

### 6. **ViewModel集成**

#### `ServeAnalysisViewModel.swift`
完整工作流集成:
```swift
// 数据流
相机帧 → 姿势估计 → 关键点平滑 → 生物力学计算 → UI更新
```

**新增功能**:
- `currentMetrics`: 发布当前生物力学指标
- `calibrationConfig`: 发布校准配置
- `updateCalibration()`: 更新用户身高
- `resetAnalyzer()`: 重置滤波器状态
- 自动应用校准参数到分析器

### 7. **主视图升级**

#### `ServeAnalysisView.swift`
UI增强:
- 校准按钮(显示校准状态)
- 指标覆盖层集成
- 重置分析器按钮
- 首次启动自动显示校准界面
- 简化的状态指示器

---

## 📊 关键技术实现

### 3D角度计算
```swift
// 使用向量点积和余弦定理
cosθ = (v1 · v2) / (|v1| × |v2|)
angle = arccos(cosθ) × 180/π
```

### 速度计算
```swift
velocity = distance3D(current, previous) / dt
// 应用校准缩放
realVelocity = velocity × pixelToMeterScale
```

### 自动校准
```swift
// 基于躯干长度估算
torsoLength = distance(shoulderMid, hipMid)
expectedTorso = userHeight × 0.3
scale = expectedTorso / torsoLength
```

---

## 🎯 符合PRD要求

✅ **One Euro Filter平滑** (第2章技术栈要求)  
✅ **髋肩分离度计算** (里程碑1核心指标)  
✅ **膝关节屈曲度** (里程碑1核心指标)  
✅ **拍头速度(手腕速度)** (里程碑1核心指标)  
✅ **击球高度** (里程碑1核心指标)  
✅ **像素到米校准** (第3章技术要求)  
✅ **实时指标反馈** (里程碑1输出要求)  

---

## 🚀 下一步建议

1. **发球阶段检测** - 识别准备/蓄力/击球/随挥阶段
2. **反馈生成系统** - 基于指标生成自然语言建议
3. **数据持久化** - 保存分析会话和历史趋势
4. **性能优化** - 验证60 FPS目标
5. **TrackNet球追踪** - 里程碑2功能

---

## 📝 使用说明

### 首次使用
1. 启动应用,自动显示校准界面
2. 输入身高(厘米或英尺/英寸)
3. 点击"保存并开始分析"
4. 允许相机权限
5. 点击"开始分析"

### 实时分析
- 骨架会实时显示在相机画面上
- 顶部显示生物力学指标卡片
- 绿色圆点表示指标良好,黄色警告,红色需改进
- 点击"重置"清除滤波器历史数据

### 重新校准
- 点击顶部"已校准"按钮
- 修改身高后保存
- 分析器自动应用新参数

---

## 📦 新增文件清单

```
Apex/
├── Domain/
│   ├── Entities/
│   │   └── BiomechanicsMetrics.swift          ✨ 新增
│   └── Services/
│       ├── BiomechanicsAnalyzer.swift         ✨ 新增
│       └── CalibrationManager.swift           ✨ 新增
├── Core/
│   └── Filters/
│       └── OneEuroFilter.swift                ✨ 新增
└── Features/
    └── ServeAnalysis/
        ├── ViewModels/
        │   └── ServeAnalysisViewModel.swift   🔄 更新
        └── Views/
            ├── CalibrationView.swift          ✨ 新增
            ├── MetricsOverlayView.swift       ✨ 新增
            └── ServeAnalysisView.swift        🔄 更新
```

**总计**: 5个新文件 + 2个更新文件
