import SwiftUI

/// 校准视图 - 用于用户输入身高进行校准
struct CalibrationView: View {
    
    @ObservedObject var viewModel: ServeAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var heightCm: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var useMetric: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("为了准确计算生物力学指标，请输入您的身高")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } header: {
                    Text("身高校准")
                }
                
                Section {
                    Picker("单位", selection: $useMetric) {
                        Text("厘米").tag(true)
                        Text("英尺/英寸").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    if useMetric {
                        HStack {
                            TextField("例如: 180", text: $heightCm)
                                .keyboardType(.decimalPad)
                            Text("cm")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            TextField("英尺", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                            Text("'")
                            TextField("英寸", text: $heightInches)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                            Text("\"")
                        }
                    }
                } header: {
                    Text("请输入身高")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("提高精度", systemImage: "target")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Text("准确的身高数据可帮助系统计算真实的击球高度、拍头速度等关键指标")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: saveCalibration) {
                        HStack {
                            Spacer()
                            Text("保存并开始分析")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!isValidInput)
                    
                    if viewModel.calibrationConfig?.isCalibrated == true {
                        Button(role: .destructive) {
                            skipCalibration()
                        } label: {
                            HStack {
                                Spacer()
                                Text("跳过 (使用上次校准)")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("校准")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingCalibration()
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isValidInput: Bool {
        if useMetric {
            guard let height = Float(heightCm), height > 0, height < 300 else {
                return false
            }
            return true
        } else {
            guard let feet = Int(heightFeet),
                  let inches = Int(heightInches),
                  feet > 0, feet < 9,
                  inches >= 0, inches < 12 else {
                return false
            }
            return true
        }
    }
    
    private func saveCalibration() {
        let heightInCm: Float
        
        if useMetric {
            heightInCm = Float(heightCm) ?? 0
        } else {
            let feet = Float(heightFeet) ?? 0
            let inches = Float(heightInches) ?? 0
            // Convert to cm: 1 foot = 30.48 cm, 1 inch = 2.54 cm
            heightInCm = feet * 30.48 + inches * 2.54
        }
        
        viewModel.updateCalibration(heightCm: heightInCm)
        dismiss()
    }
    
    private func skipCalibration() {
        dismiss()
    }
    
    private func loadExistingCalibration() {
        if let config = viewModel.calibrationConfig, config.isCalibrated {
            heightCm = String(format: "%.0f", config.userHeightCm)
            
            // Convert to feet/inches
            let totalInches = config.userHeightCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            heightFeet = "\(feet)"
            heightInches = "\(inches)"
        }
    }
}

#Preview {
    CalibrationView(viewModel: ServeAnalysisViewModel())
}
