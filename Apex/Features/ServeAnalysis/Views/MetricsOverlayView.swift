import SwiftUI

/// 生物力学指标显示视图
/// Displays real-time biomechanics metrics overlay on the camera feed.
struct MetricsOverlayView: View {
    
    let metrics: BiomechanicsMetrics?
    let isCalibrated: Bool
    
    var body: some View {
        VStack {
            // 顶部指标面板
            if let metrics = metrics, metrics.isValid {
                metricsPanel(metrics)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
            } else if !isCalibrated {
                calibrationPrompt
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Metrics Panel
    
    @ViewBuilder
    private func metricsPanel(_ metrics: BiomechanicsMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生物力学数据")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                // 膝关节屈曲
                if let leftKnee = metrics.leftKneeFlexion {
                    metricCard(
                        title: "左膝屈曲",
                        value: String(format: "%.0f°", leftKnee),
                        status: kneeFlexionStatus(leftKnee)
                    )
                }
                
                if let rightKnee = metrics.rightKneeFlexion {
                    metricCard(
                        title: "右膝屈曲",
                        value: String(format: "%.0f°", rightKnee),
                        status: kneeFlexionStatus(rightKnee)
                    )
                }
                
                // 髋肩分离
                if let separation = metrics.hipShoulderSeparation {
                    metricCard(
                        title: "髋肩分离",
                        value: String(format: "%.0f°", separation),
                        status: hipShoulderSeparationStatus(separation)
                    )
                }
                
                // 击球高度
                if let height = metrics.contactHeight {
                    metricCard(
                        title: "击球高度",
                        value: String(format: "%.2fm", height),
                        status: contactHeightStatus(height)
                    )
                }
                
                // 拍头速度
                if let velocity = metrics.rightWristVelocity {
                    metricCard(
                        title: "手腕速度",
                        value: String(format: "%.1f m/s", velocity),
                        status: wristVelocityStatus(velocity)
                    )
                }
                
                // 肘关节角度
                if let elbow = metrics.rightElbowAngle {
                    metricCard(
                        title: "右肘角度",
                        value: String(format: "%.0f°", elbow),
                        status: .neutral
                    )
                }
            }
        }
    }
    
    // MARK: - Metric Card
    
    private func metricCard(title: String, value: String, status: MetricStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                statusIndicator(status)
            }
        }
        .padding(8)
        .background(status.backgroundColor.opacity(0.2))
        .cornerRadius(8)
    }
    
    private func statusIndicator(_ status: MetricStatus) -> some View {
        Circle()
            .fill(status.color)
            .frame(width: 8, height: 8)
    }
    
    // MARK: - Calibration Prompt
    
    private var calibrationPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "ruler")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("需要校准")
                .font(.headline)
            
            Text("请先输入身高以获得准确的分析数据")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Status Evaluation
    
    enum MetricStatus {
        case good
        case warning
        case poor
        case neutral
        
        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .yellow
            case .poor: return .red
            case .neutral: return .gray
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .poor: return .red
            case .neutral: return .gray
            }
        }
    }
    
    /// 评估膝关节屈曲状态 (理想范围: 40-60度)
    private func kneeFlexionStatus(_ angle: Float) -> MetricStatus {
        if angle >= 40 && angle <= 60 {
            return .good
        } else if angle >= 30 && angle < 40 || angle > 60 && angle <= 75 {
            return .warning
        } else {
            return .poor
        }
    }
    
    /// 评估髋肩分离状态 (理想范围: 30-50度)
    private func hipShoulderSeparationStatus(_ angle: Float) -> MetricStatus {
        if angle >= 30 && angle <= 50 {
            return .good
        } else if angle >= 20 && angle < 30 || angle > 50 && angle <= 60 {
            return .warning
        } else {
            return .poor
        }
    }
    
    /// 评估击球高度 (理想: > 2.4m for tall players)
    private func contactHeightStatus(_ height: Float) -> MetricStatus {
        if height >= 2.4 {
            return .good
        } else if height >= 2.2 {
            return .warning
        } else {
            return .poor
        }
    }
    
    /// 评估手腕速度 (理想: > 15 m/s)
    private func wristVelocityStatus(_ velocity: Float) -> MetricStatus {
        if velocity >= 15 {
            return .good
        } else if velocity >= 10 {
            return .warning
        } else {
            return .poor
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        MetricsOverlayView(
            metrics: BiomechanicsMetrics(
                leftKneeFlexion: 45,
                rightKneeFlexion: 50,
                leftElbowAngle: 120,
                rightElbowAngle: 130,
                shoulderRotation: 45,
                hipRotation: 10,
                contactHeight: 2.5,
                leftWristHeight: 1.8,
                rightWristHeight: 2.5,
                rightWristVelocity: 18,
                leftWristVelocity: 5,
                timestamp: Date().timeIntervalSince1970
            ),
            isCalibrated: true
        )
    }
}
