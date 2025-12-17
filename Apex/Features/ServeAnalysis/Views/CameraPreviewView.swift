import SwiftUI
import AVFoundation

/// 相机预览视图
/// A SwiftUI wrapper for AVCaptureVideoPreviewLayer.
struct CameraPreviewView: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // 确保预览层方向正确 (默认为 Portrait)
        if let connection = view.videoPreviewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        // No updates needed for the session itself
    }
    
    /// 内部 UIView 子类，用于持有 PreviewLayer
    class VideoPreviewUIView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
