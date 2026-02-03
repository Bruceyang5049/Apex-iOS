import SwiftUI

/// 性能监控叠加视图
/// Displays real-time performance metrics as an overlay.
struct PerformanceOverlayView: View {
    
    @ObservedObject var monitor: PerformanceMonitor
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题栏
            header
            
            // 性能指标
            if isExpanded {
                metrics
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(monitor.isMonitoring ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .animation(.easeInOut, value: monitor.isMonitoring)
            
            Text("性能监控")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Metrics
    
    private var metrics: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            VStack(spacing: 6) {
                // FPS
                metricRow(
                    icon: "📹",
                    label: "FPS",
                    value: String(format: "%.1f", monitor.currentFPS),
                    status: fpsStatus
                )
                
                // 推理时间
                metricRow(
                    icon: "⚡️",
                    label: "推理",
                    value: String(format: "%.1f ms", monitor.averageInferenceTime * 1000),
                    status: inferenceStatus
                )
                
                // 内存使用
                metricRow(
                    icon: "💾",
                    label: "内存",
                    value: String(format: "%.0f MB", monitor.memoryUsageMB),
                    status: memoryStatus
                )
                
                // CPU使用
                metricRow(
                    icon: "🖥️",
                    label: "CPU",
                    value: String(format: "%.1f%%", monitor.cpuUsage),
                    status: cpuStatus
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
    
    // MARK: - Metric Row
    
    private func metricRow(icon: String, label: String, value: String, status: MetricStatus) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
            
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 40, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(status.color)
            
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(status.color.opacity(0.1))
        )
    }
    
    // MARK: - Status Calculation
    
    private var fpsStatus: MetricStatus {
        if monitor.currentFPS >= 45 {
            return .excellent
        } else if monitor.currentFPS >= 30 {
            return .good
        } else if monitor.currentFPS >= 20 {
            return .warning
        } else {
            return .critical
        }
    }
    
    private var inferenceStatus: MetricStatus {
        let ms = monitor.averageInferenceTime * 1000
        if ms < 30 {
            return .excellent
        } else if ms < 50 {
            return .good
        } else if ms < 100 {
            return .warning
        } else {
            return .critical
        }
    }
    
    private var memoryStatus: MetricStatus {
        if monitor.memoryUsageMB < 150 {
            return .excellent
        } else if monitor.memoryUsageMB < 250 {
            return .good
        } else if monitor.memoryUsageMB < 400 {
            return .warning
        } else {
            return .critical
        }
    }
    
    private var cpuStatus: MetricStatus {
        if monitor.cpuUsage < 40 {
            return .excellent
        } else if monitor.cpuUsage < 60 {
            return .good
        } else if monitor.cpuUsage < 80 {
            return .warning
        } else {
            return .critical
        }
    }
}

// MARK: - Metric Status

private enum MetricStatus {
    case excellent
    case good
    case warning
    case critical
    
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                PerformanceOverlayView(monitor: {
                    let monitor = PerformanceMonitor()
                    Task { @MainActor in
                        monitor.currentFPS = 58.3
                        monitor.averageInferenceTime = 0.028
                        monitor.memoryUsageMB = 145.2
                        monitor.cpuUsage = 42.5
                        monitor.isMonitoring = true
                    }
                    return monitor
                }())
                .frame(width: 200)
                .padding()
            }
        }
    }
}
