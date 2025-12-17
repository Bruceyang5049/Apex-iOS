import SwiftUI

/// 骨架叠加层视图
/// Renders the pose skeleton on top of the camera feed using high-performance Canvas.
struct PoseOverlayView: View {
    
    let poseResult: PoseEstimationResult?
    
    // MediaPipe Pose Topology (Simplified for MVP)
    // 定义关键点连接关系
    private let connections: [(Int, Int)] = [
        (11, 12), (11, 23), (12, 24), (23, 24), // Torso
        (11, 13), (13, 15), // Left Arm
        (12, 14), (14, 16), // Right Arm
        (23, 25), (25, 27), (27, 29), (27, 31), // Left Leg
        (24, 26), (26, 28), (28, 30), (28, 32)  // Right Leg
    ]
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard let pose = poseResult, !pose.landmarks.isEmpty else { return }
                
                // 1. 计算坐标映射参数
                // Calculate scaling and offset to match .resizeAspectFill behavior.
                // 假设视频输入是 1080x1920 (9:16)
                let videoAspectRatio: CGFloat = 9.0 / 16.0
                let viewAspectRatio = size.width / size.height
                
                var scale: CGFloat
                var xOffset: CGFloat = 0
                var yOffset: CGFloat = 0
                
                if viewAspectRatio > videoAspectRatio {
                    // 视图比视频宽 -> 适配宽度，裁剪高度 (Top/Bottom)
                    // View is wider than video -> Fit width, crop height
                    scale = size.width
                    let scaledHeight = size.width / videoAspectRatio
                    yOffset = (scaledHeight - size.height) / 2
                } else {
                    // 视图比视频窄 (通常是手机竖屏) -> 适配高度，裁剪宽度 (Left/Right)
                    // View is narrower than video -> Fit height, crop width
                    scale = size.height * videoAspectRatio // 这里 scale 代表视频缩放后的宽度
                    // Wait, logic check:
                    // If we fit height: scaledHeight = size.height.
                    // scaledWidth = size.height * videoAspectRatio.
                    // But normalized coordinates are 0..1.
                    // So x * scaledWidth gives x position relative to the video frame.
                    // Then we need to center that frame.
                    
                    // Let's refine the math:
                    // We want to map normalized (0,0)-(1,1) to a rect that covers the screen (AspectFill).
                    
                    let videoSize = CGSize(width: 1080, height: 1920) // Reference size
                    let scaleFactor = max(size.width / videoSize.width, size.height / videoSize.height)
                    
                    let renderedWidth = videoSize.width * scaleFactor
                    let renderedHeight = videoSize.height * scaleFactor
                    
                    xOffset = (renderedWidth - size.width) / 2
                    yOffset = (renderedHeight - size.height) / 2
                    
                    // 重新定义 scale 为渲染后的尺寸
                    // Redefine scale variables for the mapping function
                    // We will map directly using the rendered dimensions.
                }
                
                // 重新计算映射逻辑 (更加通用的 AspectFill 算法)
                // Re-calculating mapping logic using standard AspectFill algorithm
                let videoSize = CGSize(width: 9, height: 16) // Aspect Ratio only matters
                let scaleFactor = max(size.width / videoSize.width, size.height / videoSize.height)
                
                let renderedWidth = videoSize.width * scaleFactor
                let renderedHeight = videoSize.height * scaleFactor
                
                let offsetX = (renderedWidth - size.width) / 2
                let offsetY = (renderedHeight - size.height) / 2
                
                // 坐标转换闭包
                // Coordinate mapping closure
                let mapPoint = { (landmark: PoseLandmark) -> CGPoint in
                    let x = CGFloat(landmark.x) * renderedWidth - offsetX
                    let y = CGFloat(landmark.y) * renderedHeight - offsetY
                    return CGPoint(x: x, y: y)
                }
                
                // 2. 绘制骨骼连接 (Bones)
                // Draw connections
                for (startIdx, endIdx) in connections {
                    if let start = pose.landmark(for: startIdx),
                       let end = pose.landmark(for: endIdx) {
                        
                        let p1 = mapPoint(start)
                        let p2 = mapPoint(end)
                        
                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)
                        
                        context.stroke(path, with: .color(.white), lineWidth: 2)
                    }
                }
                
                // 3. 绘制关键点 (Joints)
                // Draw joints
                for landmark in pose.landmarks {
                    // 仅绘制身体主要关键点 (忽略面部 0-10 以保持简洁)
                    if landmark.id > 10 {
                        let point = mapPoint(landmark)
                        let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                        context.fill(Path(ellipseIn: rect), with: .color(red: 0.8, green: 1.0, blue: 0.0))
                    }
                }
            }
        }
    }
}
