# 生物力学模块测试指南

## 🧪 测试清单

### 1. One Euro Filter 单元测试

**测试场景**: 平滑噪声数据

```swift
func testOneEuroFilter() {
    let filter = OneEuroFilter(minCutoff: 1.0, beta: 0.007)
    
    // 模拟带噪声的数据序列
    let noisyData: [Double] = [1.0, 1.1, 0.9, 1.05, 0.95, 1.0]
    var timestamp = 0.0
    
    for value in noisyData {
        let smoothed = filter.filter(value, timestamp: timestamp)
        print("Input: \(value), Smoothed: \(smoothed)")
        timestamp += 0.033 // 30 FPS
    }
    
    // 期望: smoothed值的变化应该比input平滑
}
```

### 2. 角度计算测试

**测试场景**: 验证3D角度计算正确性

```swift
func testAngleCalculation() {
    let analyzer = BiomechanicsAnalyzer()
    
    // 创建一个90度直角的三个点
    let p1 = PoseLandmark(id: 0, x: 1, y: 0, z: 0, visibility: 1, presence: 1)
    let vertex = PoseLandmark(id: 1, x: 0, y: 0, z: 0, visibility: 1, presence: 1)
    let p2 = PoseLandmark(id: 2, x: 0, y: 1, z: 0, visibility: 1, presence: 1)
    
    let angle = analyzer.calculateAngle3D(point1: p1, vertex: vertex, point2: p2)
    
    // 期望: angle ≈ 90度 (±0.1)
    XCTAssertEqual(angle, 90.0, accuracy: 0.1)
}
```

### 3. 校准测试

**测试场景**: 验证身高校准功能

```swift
func testCalibration() {
    let manager = CalibrationManager.shared
    
    // 保存校准
    let config = CalibrationConfig(userHeightCm: 180)
    manager.saveCalibration(config)
    
    // 加载校准
    let loaded = manager.loadCalibration()
    XCTAssertEqual(loaded?.userHeightCm, 180)
    XCTAssertEqual(loaded?.userHeightMeters, 1.8)
    
    // 清除校准
    manager.clearCalibration()
    XCTAssertNil(manager.loadCalibration())
}
```

### 4. 端到端集成测试

**测试场景**: 完整的姿势→指标流程

```swift
func testBiomechanicsAnalysis() {
    let analyzer = BiomechanicsAnalyzer()
    analyzer.userHeight = 1.8 // 1.8米
    
    // 创建模拟的姿势数据(33个关键点)
    let landmarks = createMockPoseLandmarks()
    let poseResult = PoseEstimationResult(landmarks: landmarks, timestamp: 0.0)
    
    // 执行分析
    let metrics = analyzer.analyze(poseResult: poseResult)
    
    // 验证指标有效性
    XCTAssertTrue(metrics.isValid)
    XCTAssertNotNil(metrics.rightKneeFlexion)
    XCTAssertNotNil(metrics.hipShoulderSeparation)
}
```

---

## 📱 手动测试流程

### 测试准备
1. 确保有真实iOS设备(模拟器不支持相机)
2. 在光线充足的环境中测试
3. 穿着便于识别的服装(避免宽松衣物)

### 测试步骤

#### 测试1: 校准功能
1. ✅ 首次启动应自动显示校准界面
2. ✅ 输入身高180cm,保存
3. ✅ 顶部按钮显示"已校准"(绿色)
4. ✅ 重新打开校准界面,身高应预填充

#### 测试2: 姿势检测
1. ✅ 点击"开始分析"
2. ✅ 站在相机前,全身可见
3. ✅ 骨架应实时显示在身体上
4. ✅ 关键点跟随身体移动

#### 测试3: 指标计算
1. ✅ 做发球准备动作(屈膝)
2. ✅ 观察"左膝屈曲"和"右膝屈曲"数值变化
3. ✅ 膝关节角度应在30-90度范围
4. ✅ 屈膝越深,角度越小

#### 测试4: 状态评估
1. ✅ 保持标准发球蓄力姿势
2. ✅ 膝屈曲40-60度时应显示绿色🟢
3. ✅ 浅蹲或深蹲时应显示黄色⚠️或红色🔴
4. ✅ 指标卡片颜色应实时更新

#### 测试5: 速度计算
1. ✅ 快速挥手
2. ✅ "手腕速度"应明显增加
3. ✅ 静止时速度接近0 m/s
4. ✅ 快速移动时速度>5 m/s

#### 测试6: 滤波效果
1. ✅ 轻微抖动手臂
2. ✅ 骨架应平滑跟随,无明显跳跃
3. ✅ 指标数值应稳定变化,无剧烈波动
4. ✅ 点击"重置"后,下一帧应立即响应

---

## 🐛 已知问题与解决方案

### 问题1: 指标始终为nil
**原因**: 可见度(visibility)低于阈值  
**解决**: 改善光线,确保全身可见,穿着对比度高的服装

### 问题2: 角度计算不准确
**原因**: 相机视角造成透视失真  
**解决**: MediaPipe World Landmarks已考虑3D空间,确保使用z坐标

### 问题3: 速度跳变剧烈
**原因**: 滤波器未初始化或时间戳异常  
**解决**: 点击"重置"按钮,重新开始分析

### 问题4: 校准后指标仍不准
**原因**: 躯干长度估算误差  
**解决**: 尝试多次不同姿势让系统自动校准,或调整身高输入

---

## 📊 预期性能指标

| 指标 | 目标值 | 测量方法 |
|------|--------|---------|
| 帧率 | ≥30 FPS | Xcode Instruments |
| 延迟 | <100ms | 手动计时 |
| 膝角度精度 | ±5° | 与量角器对比 |
| 高度精度 | ±10cm | 与实际测量对比 |
| CPU占用 | <50% | Xcode Debug Navigator |
| 内存占用 | <200MB | Xcode Debug Navigator |

---

## ✅ 验收标准

MVP阶段生物力学模块合格标准:

- [ ] 能准确检测33个关键点(visibility > 0.5)
- [ ] 膝关节角度计算误差<10度
- [ ] 髋肩分离度能正确反映躯干旋转
- [ ] 击球高度与实际高度误差<15%
- [ ] 速度计算无明显跳变(滤波生效)
- [ ] 校准功能可持久化保存
- [ ] UI指标实时更新,无卡顿
- [ ] 状态评估(绿/黄/红)符合精英参考范围

---

## 🔍 调试技巧

### 1. 打印详细日志
在`BiomechanicsAnalyzer.analyze()`中添加:
```swift
print("📊 Metrics: Knee=\(leftKnee ?? 0)° Sep=\(hipShoulderSeparation ?? 0)° Height=\(contactHeight ?? 0)m")
```

### 2. 可视化关键点ID
在`PoseOverlayView`中显示关键点编号,验证索引正确性

### 3. 导出原始数据
保存`PoseLandmark`和`BiomechanicsMetrics`到JSON文件,离线分析

### 4. 对比精英数据
录制专业球员视频,验证算法输出是否合理

---

## 📚 参考资料

- [MediaPipe Pose Landmarks](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker)
- [One Euro Filter Paper](https://cristal.univ-lille.fr/~casiez/1euro/)
- [Tennis Biomechanics Standards](https://www.itftennis.com/en/science-medicine/)
