import SwiftUI

/// 发球分析主视图
/// Main view for the Serve Analysis feature.
struct ServeAnalysisView: View {
    
    @ObservedObject var viewModel: ServeAnalysisViewModel
    
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
            
            // Layer 3: UI Controls & Debug Info
            // UI 控制层
            VStack {
                // 顶部状态栏
                HStack {
                    if let error = viewModel.errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Debug Info
                    if viewModel.isAnalyzing {
                        VStack(alignment: .trailing) {
                            Text("AI Active")
                                .foregroundColor(.green)
                            if let pose = viewModel.currentPose {
                                Text("Landmarks: \(pose.landmarks.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 底部控制栏
                Button(action: {
                    if viewModel.isAnalyzing {
                        viewModel.stopAnalysis()
                    } else {
                        viewModel.startAnalysis()
                    }
                }) {
                    Text(viewModel.isAnalyzing ? "Stop Analysis" : "Start Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isAnalyzing ? Color.red : Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 自动启动 (可选，或者等待用户点击)
            // viewModel.startAnalysis()
        }
        .onDisappear {
            viewModel.stopAnalysis()
        }
    }
}
