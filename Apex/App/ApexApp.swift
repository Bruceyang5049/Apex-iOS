import SwiftUI

@main
struct ApexApp: App {
    
    // Dependency Injection Container
    // 在 App 入口处组装核心依赖
    @StateObject private var serveAnalysisViewModel: ServeAnalysisViewModel
    
    init() {
        // 1. 创建具体实现
        let cameraManager = CameraManager()
        let poseEstimator = MediaPipePoseEstimator()
        
        // 2. 注入 ViewModel
        // 注意：StateObject 的初始化需要使用 _viewModel = StateObject(...)
        _serveAnalysisViewModel = StateObject(wrappedValue: ServeAnalysisViewModel(
            cameraManager: cameraManager,
            poseEstimator: poseEstimator
        ))
    }
    
    var body: some Scene {
        WindowGroup {
            // 3. 权限检查包裹主视图
            PermissionsView {
                ServeAnalysisView(viewModel: serveAnalysisViewModel)
            }
        }
    }
}
