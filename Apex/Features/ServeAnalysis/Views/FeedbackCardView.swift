import SwiftUI

/// 反馈卡片视图
/// Displays individual feedback items with severity-based styling and animation.
struct FeedbackCardView: View {
    
    let item: FeedbackItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题行
            HStack(spacing: 12) {
                // 严重程度指示器
                Circle()
                    .fill(severityColor(item.severity))
                    .frame(width: 12, height: 12)
                
                // 类别图标 + 标题
                HStack(spacing: 8) {
                    Text(categoryIcon(item.category))
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoryName(item.category))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text(item.message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(isExpanded ? .max : 2)
                    }
                    
                    Spacer()
                }
                
                // 展开按钮
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // 展开内容
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(backgroundColor)
        .border(
            severityColor(item.severity).opacity(0.3),
            width: 1.5
        )
        .cornerRadius(10)
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .opacity(0.3)
            
            // 严重程度标签
            HStack {
                Text("严重程度:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(severityLabel(item.severity))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor(item.severity).opacity(0.2))
                    .foregroundColor(severityColor(item.severity))
                    .cornerRadius(4)
            }
            
            // 可执行建议
            if item.isActionable {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("改进方案")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    
                    Text(item.actionable)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(.max)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // 性能影响
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("性能影响")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                impactBar
            }
            .padding(8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(6)
        }
    }
    
    private var impactBar: some View {
        HStack(spacing: 8) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(impactPercentage()))
                }
            }
            .frame(height: 6)
            
            // 百分比文本
            Text(String(format: "+%.0f%%", impactPercentage() * 100))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    // MARK: - Styling
    
    private var backgroundColor: Color {
        switch item.severity {
        case .critical:
            return Color.red.opacity(0.05)
        case .warning:
            return Color.orange.opacity(0.05)
        case .good:
            return Color.blue.opacity(0.05)
        case .excellent:
            return Color.green.opacity(0.05)
        }
    }
    
    private func severityColor(_ severity: FeedbackSeverity) -> Color {
        switch severity {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .good:
            return .blue
        case .excellent:
            return .green
        }
    }
    
    private func severityLabel(_ severity: FeedbackSeverity) -> String {
        switch severity {
        case .critical:
            return "🔴 需改进"
        case .warning:
            return "🟡 警告"
        case .good:
            return "🔵 良好"
        case .excellent:
            return "🟢 优秀"
        }
    }
    
    private func categoryIcon(_ category: FeedbackCategory) -> String {
        switch category {
        case .kneeFlexion:
            return "📏"
        case .hipShoulderSeparation:
            return "📐"
        case .contactHeight:
            return "📍"
        case .wristVelocity:
            return "⚡️"
        case .elbowAngle:
            return "🔄"
        case .torsoRotation:
            return "🌀"
        case .overallTechnique:
            return "🎾"
        }
    }
    
    private func categoryName(_ category: FeedbackCategory) -> String {
        switch category {
        case .kneeFlexion:
            return "膝屈曲"
        case .hipShoulderSeparation:
            return "髋肩分离"
        case .contactHeight:
            return "击球高度"
        case .wristVelocity:
            return "手腕速度"
        case .elbowAngle:
            return "肘角度"
        case .torsoRotation:
            return "躯干旋转"
        case .overallTechnique:
            return "整体技术"
        }
    }
    
    private func impactPercentage() -> Double {
        // 提取impact string中的数字
        // 例如: "+15%发球速度" → 0.15
        let pattern = "\\+(\\d+(\\.\\d+)?)%"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: item.impact, options: [], range: NSRange(item.impact.startIndex..., in: item.impact)),
           let range = Range(match.range(at: 1), in: item.impact),
           let value = Double(item.impact[range]) {
            return min(value / 100.0, 1.0)  // 转换为百分比，最大1.0
        }
        return 0
    }
}

// MARK: - Feedback Batch View (用于会话详情中显示多个反馈)

struct FeedbackBatchView: View {
    
    let items: [FeedbackItem]
    @State private var selectedCategory: FeedbackCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI教练反馈")
                .font(.headline)
            
            // 分类标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { selectedCategory = nil }) {
                        Text("全部")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                            .cornerRadius(6)
                    }
                    
                    ForEach(uniqueCategories, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Text(categoryShortName(category))
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 反馈卡片列表
            VStack(spacing: 10) {
                ForEach(filteredItems) { item in
                    FeedbackCardView(item: item)
                }
            }
        }
    }
    
    private var uniqueCategories: [FeedbackCategory] {
        Array(Set(items.map { $0.category }))
            .sorted { categoryIndex($0) < categoryIndex($1) }
    }
    
    private var filteredItems: [FeedbackItem] {
        if let selected = selectedCategory {
            return items.filter { $0.category == selected }
        }
        return items
    }
    
    private func categoryShortName(_ category: FeedbackCategory) -> String {
        switch category {
        case .kneeFlexion:
            return "膝"
        case .hipShoulderSeparation:
            return "髋"
        case .contactHeight:
            return "高"
        case .wristVelocity:
            return "速"
        case .elbowAngle:
            return "肘"
        case .torsoRotation:
            return "旋"
        case .overallTechnique:
            return "整体"
        }
    }
    
    private func categoryIndex(_ category: FeedbackCategory) -> Int {
        [
            FeedbackCategory.kneeFlexion,
            .hipShoulderSeparation,
            .contactHeight,
            .wristVelocity,
            .elbowAngle,
            .torsoRotation,
            .overallTechnique
        ].firstIndex(of: category) ?? 0
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            FeedbackCardView(item: FeedbackItem(
                severity: .excellent,
                category: .kneeFlexion,
                message: "膝屈曲角度优秀",
                actionable: "保持当前角度，这是理想的蓄力动作",
                impact: "+12%发球速度"
            ))
            
            FeedbackCardView(item: FeedbackItem(
                severity: .warning,
                category: .hipShoulderSeparation,
                message: "髋肩分离不足",
                actionable: "增强躯干旋转，目标增加15-20度分离",
                impact: "+18%旋转速度"
            ))
            
            FeedbackCardView(item: FeedbackItem(
                severity: .critical,
                category: .contactHeight,
                message: "击球高度过低",
                actionable: "增强跳跃高度，延迟击球时机0.1-0.2秒",
                impact: "+25%成功率"
            ))
        }
        .padding()
    }
}
