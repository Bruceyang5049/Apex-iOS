import Foundation

/// 校准配置
/// Calibration settings for converting normalized/world coordinates to real-world measurements.
struct CalibrationConfig: Codable, Equatable {
    
    /// 用户身高 (厘米)
    var userHeightCm: Float
    
    /// 用户身高 (米)
    var userHeightMeters: Float {
        return userHeightCm / 100.0
    }
    
    /// 校准时间戳
    let calibrationDate: Date
    
    /// 是否已校准
    var isCalibrated: Bool {
        return userHeightCm > 0
    }
    
    init(userHeightCm: Float = 0) {
        self.userHeightCm = userHeightCm
        self.calibrationDate = Date()
    }
}

/// 校准管理器
/// Manages calibration settings persistence and retrieval.
class CalibrationManager {
    
    static let shared = CalibrationManager()
    
    private let userDefaults = UserDefaults.standard
    private let calibrationKey = "com.apex.calibration"
    
    private init() {}
    
    /// 保存校准配置
    func saveCalibration(_ config: CalibrationConfig) {
        if let encoded = try? JSONEncoder().encode(config) {
            userDefaults.set(encoded, forKey: calibrationKey)
            print("✅ Calibration saved: \(config.userHeightCm) cm")
        }
    }
    
    /// 加载校准配置
    func loadCalibration() -> CalibrationConfig? {
        guard let data = userDefaults.data(forKey: calibrationKey),
              let config = try? JSONDecoder().decode(CalibrationConfig.self, from: data) else {
            return nil
        }
        return config
    }
    
    /// 清除校准
    func clearCalibration() {
        userDefaults.removeObject(forKey: calibrationKey)
        print("🗑️ Calibration cleared")
    }
    
    /// 检查是否已校准
    func isCalibrated() -> Bool {
        return loadCalibration()?.isCalibrated ?? false
    }
}
