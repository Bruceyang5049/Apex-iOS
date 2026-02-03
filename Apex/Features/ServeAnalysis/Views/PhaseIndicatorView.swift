import SwiftUI

/// 发球阶段指示器视图
/// Real-time display of current serve phase with animated progress indicator.
struct PhaseIndicatorView: View {
    
    let currentPhase: ServePhase
    let phaseHistory: [ServePhaseEvent]
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 12) {
            // 当前阶段大标题
            HStack(spacing: 12) {
                Text(currentPhase.emoji)
                    .font(.system(size: 36))
                    .scaleEffect(animateProgress ? 1.1 : 1.0)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("当前阶段")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(currentPhase.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(phaseColor(currentPhase))
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // 阶段进度条
            phaseProgressBar
            
            // 阶段序列时间轴
            if !phaseHistory.isEmpty {
                phaseTimeline
            }
        }
        .onAppear {
            animatePhase()
        }
        .onChange(of: currentPhase) { _, _ in
            animatePhase()
        }
    }
    
    // MARK: - Progress Bar
    
    private var phaseProgressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Preparation
                phaseBar(
                    phase: .preparation,
                    isActive: currentPhase == .preparation || phaseIndex(.preparation) < phaseIndex(currentPhase),
                    isCompleted: phaseIndex(.preparation) < phaseIndex(currentPhase)
                )
                
                // Loading
                phaseBar(
                    phase: .loading,
                    isActive: currentPhase == .loading || phaseIndex(.loading) < phaseIndex(currentPhase),
                    isCompleted: phaseIndex(.loading) < phaseIndex(currentPhase)
                )
                
                // Contact
                phaseBar(
                    phase: .contact,
                    isActive: currentPhase == .contact || phaseIndex(.contact) < phaseIndex(currentPhase),
                    isCompleted: phaseIndex(.contact) < phaseIndex(currentPhase)
                )
                
                // Follow Through
                phaseBar(
                    phase: .followThrough,
                    isActive: currentPhase == .followThrough || phaseIndex(.followThrough) < phaseIndex(currentPhase),
                    isCompleted: phaseIndex(.followThrough) < phaseIndex(currentPhase)
                )
            }
            .padding(.horizontal)
            
            // 进度百分比
            Text(String(format: "%.0f%% 完成", phaseCompletion() * 100))
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func phaseBar(phase: ServePhase, isActive: Bool, isCompleted: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                // 进度条
                if isCompleted || isActive {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    phaseColor(phase),
                                    phaseColor(phase).opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: isCompleted ? .infinity : (isActive ? (animateProgress ? .infinity : .zero) : .zero))
                }
            }
            .frame(height: 8)
            
            // 阶段标签
            Text(phase.displayName)
                .font(.caption2)
                .foregroundColor(isActive || isCompleted ? phaseColor(phase) : .gray)
                .fontWeight(isActive ? .semibold : .regular)
        }
    }
    
    // MARK: - Timeline View
    
    private var phaseTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("阶段时间轴")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(phaseHistory.enumerated()), id: \.element.id) { index, event in
                    phaseTimelineItem(event, index: index, total: phaseHistory.count)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func phaseTimelineItem(_ event: ServePhaseEvent, index: Int, total: Int) -> some View {
        HStack(spacing: 12) {
            // 时间轴点
            VStack(spacing: 0) {
                Circle()
                    .fill(phaseColor(event.phase))
                    .frame(width: 10, height: 10)
                
                if index < total - 1 {
                    VStack(spacing: 0) {
                        Divider()
                            .frame(height: 30)
                    }
                    .frame(width: 2)
                    .foregroundColor(phaseColor(event.phase).opacity(0.3))
                }
            }
            
            // 事件信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(event.phase.emoji)
                    Text(event.phase.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    if let duration = event.duration {
                        Text(String(format: "%.2fs", duration))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(String(format: "时间戳: %.2f", event.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helpers
    
    private func phaseColor(_ phase: ServePhase) -> Color {
        switch phase {
        case .preparation:
            return .blue
        case .loading:
            return .orange
        case .contact:
            return .red
        case .followThrough:
            return .green
        }
    }
    
    private func phaseIndex(_ phase: ServePhase) -> Int {
        switch phase {
        case .preparation: return 0
        case .loading: return 1
        case .contact: return 2
        case .followThrough: return 3
        }
    }
    
    private func phaseCompletion() -> Double {
        let index = phaseIndex(currentPhase)
        let total = 4
        return Double(index) / Double(total - 1)
    }
    
    private func animatePhase() {
        withAnimation(.easeInOut(duration: 0.6)) {
            animateProgress = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animateProgress = false
        }
    }
}

// MARK: - Compact Phase Badge (用于顶部状态栏)

struct PhaseBadgeView: View {
    
    let currentPhase: ServePhase
    let quality: Float?
    
    var body: some View {
        HStack(spacing: 8) {
            Text(currentPhase.emoji)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 1) {
                Text("发球阶段")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(currentPhase.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            if let quality = quality, quality > 0 {
                Spacer()
                
                Text(String(format: "%.0f%%", quality))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(qualityColor(quality).opacity(0.2))
                    .foregroundColor(qualityColor(quality))
                    .cornerRadius(3)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func qualityColor(_ score: Float) -> Color {
        switch score {
        case 80...:
            return .green
        case 60..<80:
            return .blue
        default:
            return .orange
        }
    }
}

// MARK: - Mini Phase Indicator (用于浮动窗口中)

struct MiniPhaseIndicatorView: View {
    
    let currentPhase: ServePhase
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text(currentPhase.emoji)
                .font(.system(size: 12))
                .scaleEffect(pulse ? 1.1 : 1.0)
            
            Text(currentPhase.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(phaseColor(currentPhase).opacity(0.2))
        .foregroundColor(phaseColor(currentPhase))
        .cornerRadius(4)
        .onAppear {
            animatePulse()
        }
        .onChange(of: currentPhase) { _, _ in
            animatePulse()
        }
    }
    
    private func phaseColor(_ phase: ServePhase) -> Color {
        switch phase {
        case .preparation:
            return .blue
        case .loading:
            return .orange
        case .contact:
            return .red
        case .followThrough:
            return .green
        }
    }
    
    private func animatePulse() {
        withAnimation(.easeInOut(duration: 0.5).repeatCount(2)) {
            pulse.toggle()
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            PhaseIndicatorView(
                currentPhase: .loading,
                phaseHistory: [
                    ServePhaseEvent(phase: .preparation, timestamp: 0, keyMetrics: BiomechanicsMetrics()),
                    ServePhaseEvent(phase: .loading, timestamp: 0.5, keyMetrics: BiomechanicsMetrics())
                ]
            )
            
            Divider()
            
            PhaseBadgeView(currentPhase: .contact, quality: 85)
            
            Divider()
            
            MiniPhaseIndicatorView(currentPhase: .followThrough)
        }
        .padding()
    }
}
