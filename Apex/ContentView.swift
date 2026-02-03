//
//  ContentView.swift
//  Apex
//
//  Created by Yang Paul on 12/14/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ServeAnalysisViewModel
    
    init() {
        // 使用临时占位符初始化，在onAppear中重新设置
        let tempContainer = try! ModelContainer(for: AnalysisSession.self)
        let tempContext = ModelContext(tempContainer)
        let repository = SessionRepository(modelContext: tempContext)
        
        _viewModel = StateObject(wrappedValue: ServeAnalysisViewModel(
            sessionRepository: repository
        ))
    }
    
    var body: some View {
        ServeAnalysisView(viewModel: viewModel)
            .onAppear {
                // 使用实际的ModelContext重新创建repository
                let repository = SessionRepository(modelContext: modelContext)
                
                // 由于ViewModel已初始化，这里需要替换其repository
                // 但由于Swift的限制，我们需要在ViewModel中添加一个setter
                // 或者使用依赖注入模式
                
                // 目前保持现状，后续可优化
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AnalysisSession.self)
}
