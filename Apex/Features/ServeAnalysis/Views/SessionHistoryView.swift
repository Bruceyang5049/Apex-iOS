import SwiftUI
import SwiftData

/// 发球分析历史记录视图
/// Displays a list of previous serve analysis sessions with filtering and sorting.
struct SessionHistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var repository: SessionRepository?
    @State private var sessions: [AnalysisSession] = []
    @State private var selectedSession: AnalysisSession?
    @State private var sortBy: SortOption = .dateDescending
    @State private var filterQuality: FilterOption = .all
    @State private var showDeleteAlert = false
    @State private var sessionToDelete: AnalysisSession?
    @State private var isLoading = false
    
    enum SortOption: String, CaseIterable {
        case dateDescending = "日期(最新)"
        case dateAscending = "日期(最早)"
        case qualityDescending = "质量评分"
        case durationLongest = "时长(最长)"
        
        var displayName: String { self.rawValue }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "全部"
        case excellent = "优秀(80+)"
        case good = "良好(60-79)"
        case needImprovement = "需改进(<60)"
        
        var displayName: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 工具栏
                toolbar
                
                // 内容区域
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("加载中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else if filteredAndSortedSessions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("发球分析历史")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadSessions()
        }
        .alert("删除会话", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
        } message: {
            Text("确定要删除这个分析会话吗？此操作无法撤销。")
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session, repository: repository)
        }
    }
    
    // MARK: - UI Components
    
    private var toolbar: some View {
        VStack(spacing: 12) {
            // 排序选项
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { sortBy = option }) {
                            HStack(spacing: 4) {
                                Image(systemName: option == sortBy ? "checkmark.circle.fill" : "circle")
                                    .font(.caption2)
                                Text(option.displayName)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(option == sortBy ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(option == sortBy ? .white : .primary)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 质量筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button(action: { filterQuality = option }) {
                            Text(option.displayName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(option == filterQuality ? Color.green : Color.gray.opacity(0.2))
                                .foregroundColor(option == filterQuality ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
    
    private var list: some View {
        List {
            ForEach(filteredAndSortedSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session, repository: repository)) {
                    sessionRow(session)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        sessionToDelete = session
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    
                    Button {
                        exportSession(session)
                    } label: {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func sessionRow(_ session: AnalysisSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行: 日期 + 质量评分
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.formattedDate)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(String(format: "时长: %.1f 秒", session.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 质量评分徽章
                VStack(alignment: .trailing, spacing: 2) {
                    Text(session.qualityLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(qualityColor(session.overallQualityScore))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(String(format: "%.0f%%", session.overallQualityScore))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // 指标行
            HStack(spacing: 16) {
                metricBadge(
                    icon: "📹",
                    label: "FPS",
                    value: String(format: "%.1f", session.averageFPS)
                )
                
                metricBadge(
                    icon: "🎾",
                    label: "阶段",
                    value: "\(session.phaseEventsCount)"
                )
                
                metricBadge(
                    icon: "💬",
                    label: "反馈",
                    value: "\(session.feedbackItemsCount)"
                )
                
                Spacer()
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }
    
    private func metricBadge(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.system(size: 14))
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(width: 50)
        .padding(6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("暂无分析历史")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("完成一次发球分析后，历史记录将显示在这里")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Data Loading & Processing
    
    private var filteredAndSortedSessions: [AnalysisSession] {
        var filtered = sessions
        
        // 应用质量筛选
        switch filterQuality {
        case .all:
            break
        case .excellent:
            filtered = filtered.filter { $0.overallQualityScore >= 80 }
        case .good:
            filtered = filtered.filter { $0.overallQualityScore >= 60 && $0.overallQualityScore < 80 }
        case .needImprovement:
            filtered = filtered.filter { $0.overallQualityScore < 60 }
        }
        
        // 应用排序
        switch sortBy {
        case .dateDescending:
            filtered.sort { $0.timestamp > $1.timestamp }
        case .dateAscending:
            filtered.sort { $0.timestamp < $1.timestamp }
        case .qualityDescending:
            filtered.sort { $0.overallQualityScore > $1.overallQualityScore }
        case .durationLongest:
            filtered.sort { $0.duration > $1.duration }
        }
        
        return filtered
    }
    
    private func loadSessions() {
        isLoading = true
        Task {
            do {
                if repository == nil {
                    repository = SessionRepository(modelContext: modelContext)
                }
                sessions = try repository?.fetchRecent(limit: 100) ?? []
            } catch {
                errorMessage = "加载历史记录失败: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func deleteSession(_ session: AnalysisSession) {
        Task {
            do {
                try repository?.delete(session)
                loadSessions()
            } catch {
                errorMessage = "删除失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func exportSession(_ session: AnalysisSession) {
        Task {
            do {
                let url = try repository?.exportToJSON(session)
                if let url = url {
                    print("✅ Session exported to: \(url)")
                }
            } catch {
                errorMessage = "导出失败: \(error.localizedDescription)"
            }
        }
    }
    
    @State private var errorMessage: String?
    
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

// MARK: - Session Detail View

struct SessionDetailView: View {
    
    let session: AnalysisSession
    let repository: SessionRepository?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 基本信息卡片
                basicInfoCard
                
                // 阶段信息
                if !session.phaseEvents.isEmpty {
                    phaseSection
                }
                
                // 反馈信息
                if !session.feedbackItems.isEmpty {
                    feedbackSection
                }
                
                // 指标卡片
                metricsCard
            }
            .padding()
        }
        .navigationTitle("分析详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("分析时间")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(session.formattedDate)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("整体评分")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.0f%%", session.overallQualityScore))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(qualityColor(session.overallQualityScore))
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                metricItem(icon: "⏱️", label: "时长", value: String(format: "%.1f秒", session.duration))
                metricItem(icon: "📹", label: "FPS", value: String(format: "%.1f", session.averageFPS))
                metricItem(icon: "🎾", label: "阶段数", value: "\(session.phaseEventsCount)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var phaseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发球阶段")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(session.phaseEvents) { event in
                    phaseEventRow(event)
                }
            }
        }
    }
    
    private func phaseEventRow(_ event: ServePhaseEvent) -> some View {
        HStack(spacing: 12) {
            Text(event.phase.emoji)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.phase.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let duration = event.duration {
                    Text(String(format: "耗时 %.2f 秒", duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("改进建议 (\(session.feedbackItemsCount)条)")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(session.feedbackItems) { item in
                    FeedbackCardView(item: item)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关键指标")
                .font(.headline)
            
            VStack(spacing: 10) {
                metricsRow(
                    icon: "📏",
                    name: "左膝屈曲",
                    value: String(format: "%.1f°", session.averageMetrics.leftKneeFlexion ?? 0)
                )
                
                metricsRow(
                    icon: "📏",
                    name: "右膝屈曲",
                    value: String(format: "%.1f°", session.averageMetrics.rightKneeFlexion ?? 0)
                )
                
                metricsRow(
                    icon: "📐",
                    name: "髋肩分离",
                    value: String(format: "%.1f°", session.averageMetrics.hipShoulderSeparation ?? 0)
                )
                
                metricsRow(
                    icon: "📏",
                    name: "击球高度",
                    value: String(format: "%.2f m", session.averageMetrics.contactHeight ?? 0)
                )
                
                metricsRow(
                    icon: "⚡️",
                    name: "手腕速度",
                    value: String(format: "%.1f m/s", session.averageMetrics.rightWristVelocity ?? 0)
                )
            }
        }
    }
    
    private func metricsRow(icon: String, name: String, value: String) -> some View {
        HStack {
            Text(icon)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    private func metricItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 16))
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
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

#Preview {
    SessionHistoryView()
}
