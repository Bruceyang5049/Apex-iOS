import Foundation
import AVFoundation

/// 相机服务错误
enum CameraError: Error {
    case unauthorized
    case configurationFailed
    case inputCreationFailed
    case outputCreationFailed
}

/// 负责相机捕获和帧分发的服务类
/// Manages camera session and provides an asynchronous stream of video frames.
class CameraManager: NSObject, ObservableObject {
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.apex.cameraSessionQueue")
    
    /// 视频帧流
    /// AsyncStream that yields CVPixelBuffers from the camera.
    var frameStream: AsyncStream<CVPixelBuffer> {
        AsyncStream { continuation in
            self.streamContinuation = continuation
        }
    }
    
    private var streamContinuation: AsyncStream<CVPixelBuffer>.Continuation?
    
    override init() {
        super.init()
    }
    
    /// 请求权限并配置相机
    func startSession() async throws {
        let authorized = await checkPermission()
        guard authorized else { throw CameraError.unauthorized }
        
        // 如果会话已经在运行，直接返回
        if captureSession.isRunning { return }
        
        // 在后台队列配置 Session
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                do {
                    try self.configureSession()
                    self.captureSession.startRunning()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.streamContinuation?.finish()
            self?.streamContinuation = nil
        }
    }
    
    // MARK: - Private Configuration
    
    private func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }
    
    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        captureSession.sessionPreset = .high
        
        // Input: Back Camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.configurationFailed
        }
        
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            throw CameraError.inputCreationFailed
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw CameraError.configurationFailed
        }
        
        // Output: Video Data
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            
            // 必须设置为 kCVPixelFormatType_32BGRA 以兼容 MediaPipe
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            
            // 设置代理，在专用队列上处理帧
            let videoQueue = DispatchQueue(label: "com.apex.videoOutputQueue")
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            
            // 丢弃延迟的帧
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            // 设置方向 (Portrait)
            if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        } else {
            throw CameraError.outputCreationFailed
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 将捕获到的 PixelBuffer 发送到 AsyncStream
        // Yield the pixel buffer to the stream.
        // 注意：这里不需要手动 retain，AsyncStream 会处理，但要注意 buffer 的生命周期
        streamContinuation?.yield(pixelBuffer)
    }
}
