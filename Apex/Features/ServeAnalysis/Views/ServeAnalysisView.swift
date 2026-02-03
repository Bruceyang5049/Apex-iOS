import SwiftUI

/// 发球分析主视图
/// Main view for the Serve Analysis feature.
struct ServeAnalysisView: View {
    
    @ObservedObject var viewModel: ServeAnalysisViewModel
    @State private var showCalibration = false
    
    var body: some View {
        ZStack {
            // Layer 1: Camera Preview
            // 相机预览层 (全屏)
            CameraPreviewView(session: viewModel.cameraManager.captureSession)
                .ignoresSafeArea()
            
            // Layer 2: Pose Overlay
            // 骨架叠加层
            if let pose = viewModel.currentPose {
                PoseOverlayView(poseResult: pose)
                    .ignoresSafeArea() // 确保坐标系与预览层一致
            }
            
            // Layer 3: Metrics Overlay
            // 生物力学指标叠加层
            MetricsOverlayView(
                metrics: viewModel.currentMetrics,
                isCalibrated: viewModel.calibrationConfig?.isCalibrated ?? false
            )
            
            // Layer 4: UI Controls & Debug Info
            // UI 控制层
            VStack {
                // 顶部工具栏
                HStack {
                    // 校准按钮
                    Button(action: { showCalibration = true }) {
                        HStack {
                            Image(systemName: "ruler")
                            Text(viewModel.calibrationConfig?.isCalibrated == true ? "已校准" : "校准")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(
                            viewModel.calibrationConfig?.isCalibrated == true ?
                            Color.green.opacity(0.8) : Color.orange.opacity(0.8)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // 状态指示器
                    if viewModel.isAnalyzing {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("分析中")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // 错误提示
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
                
                // 底部控制栏
                HStack(spacing: 16) {
                    // 重置按钮
                    Button(action: {
                        viewModel.resetAnalyzer()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    // 开始/停止按钮
                    Button(action: {
                        if viewModel.isAnalyzing {
                            viewModel.stopAnalysis()
                        } else {
                            viewModel.startAnalysis()
                        }
                    }) {
                        Text(viewModel.isAnalyzing ? "停止分析" : "开始分析")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.isAnalyzing ? Color.red : Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCalibration) {
            CalibrationView(viewModel: viewModel)
        }
        .onAppear {
            // 如果未校准，显示校准界面
            if viewModel.calibrationConfig?.isCalibrated != true {
                showCalibration = true
            }
        }
            // viewModel.startAnalysis()
        }
        .onDisappear {
            viewModel.stopAnalysis()
        }
    }
}
