import SwiftUI
import AVFoundation

/// 权限管理视图
/// Handles camera permission requests and states.
struct PermissionsView<Content: View>: View {
    
    /// 授权成功后显示的内容
    @ViewBuilder var content: Content
    
    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
    
    var body: some View {
        ZStack {
            switch cameraStatus {
            case .authorized:
                content
            case .notDetermined:
                requestPermissionView
            case .denied, .restricted:
                permissionDeniedView
            @unknown default:
                permissionDeniedView
            }
        }
        .onAppear {
            checkPermission()
        }
    }
    
    // MARK: - Subviews
    
    private var requestPermissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("APEX needs camera access to analyze your tennis serve biomechanics.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Button(action: {
                requestCameraAccess()
            }) {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Access Denied")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please enable camera access in Settings to use APEX.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.gray)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Logic
    
    private func checkPermission() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraStatus = granted ? .authorized : .denied
            }
        }
    }
}
