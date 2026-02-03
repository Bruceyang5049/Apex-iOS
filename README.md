# APEX: AI Tennis Performance Analyzer

[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-v2.0%20Development-green.svg)]()

> **APEX** is an iOS application designed to democratize professional tennis coaching using advanced computer vision and biomechanics analysis.

---

## 🎉 v2.0 Update - Biomechanics Engine Released!

**Release Date**: February 3, 2026

### 🆕 What's New

- ✅ **Complete Biomechanics Analysis Engine**
    - Real-time calculation of 7 key metrics
    - Knee flexion, hip-shoulder separation, contact height, wrist velocity
    - 3D vector geometry and angle calculations

- ✅ **One Euro Filter Smoothing System**
    - Adaptive noise reduction for 33 landmarks
    - Maintains low latency while eliminating jitter
    - Configurable parameters (minCutoff, beta, derivativeCutoff)

- ✅ **User Calibration System**
    - Height-based pixel-to-meter conversion
    - Support for metric (cm) and imperial (ft/in) units
    - Automatic calibration using torso length reference
    - Persistent storage via UserDefaults

- ✅ **Smart Status Evaluation UI**
    - Color-coded feedback (Green 🟢 / Yellow ⚠️ / Red 🔴)
    - Elite performance benchmark comparison
    - Real-time metrics overlay cards
    - Calibration prompt interface

### 🚧 Coming in v2.0 (In Progress)

- **Serve Phase Detection** - Automatic recognition of preparation/loading/contact/follow-through stages
- **AI Feedback Generation** - Natural language coaching suggestions based on metrics
- **Data Persistence** - Session history and progress tracking with SwiftData
- **Performance Monitoring** - FPS tracking and optimization dashboard

---

## 📋 Table of Contents

- [APEX: AI Tennis Performance Analyzer](#apex-ai-tennis-performance-analyzer)
  - [📋 Table of Contents](#-table-of-contents)
  - [🚀 Overview](#-overview)
  - [✨ Features](#-features)
  - [🏗 Architecture](#-architecture)
  - [🛠 Prerequisites](#-prerequisites)
  - [🏁 Getting Started](#-getting-started)
  - [📂 Project Structure](#-project-structure)
  - [🤝 Contributing](#-contributing)
  - [📄 License](#-license)

## 🚀 Overview

APEX leverages **Google MediaPipe** and **CoreML** to provide real-time, on-device analysis of tennis serves. By capturing video at 60 FPS, the app extracts 33-point 3D skeletal data to calculate key biomechanical metrics such as knee flexion, hip-shoulder separation, and racket head velocity.

The project follows a **Vibe Coding** philosophy: high-velocity development assisted by LLM Agents, ensuring production-grade code quality with a focus on modularity and clean architecture.

## ✨ Features

- **Real-time Pose Estimation**: Utilizes MediaPipe Vision Tasks for high-accuracy, low-latency body tracking.
- **Biomechanics Analysis**: 🆕 Real-time calculation of key metrics:
  - Knee flexion angles (left & right)
  - Hip-shoulder separation (power generation indicator)
  - Contact point height
  - Racket head velocity (wrist velocity proxy)
  - Elbow angles and torso rotation
- **Advanced Data Smoothing**: 🆕 One Euro Filter implementation for noise reduction while maintaining responsiveness.
- **User Calibration**: 🆕 Height-based calibration for accurate real-world measurements.
- **Live Metrics Display**: 🆕 Color-coded feedback with elite performance benchmarks.
- **Privacy First**: All processing happens on-device; no video data is uploaded to the cloud.
- **High Performance**: Optimized for Apple Neural Engine (ANE) with `AsyncStream` based concurrency.

## 🏗 Architecture

The project is built using **MVVM (Model-View-ViewModel)** and **Clean Architecture** principles.

- **Domain Layer**: Contains pure Swift entities and protocol definitions (Dependency Inversion).
- **Data Layer**: Implements repositories and AI services (e.g., `MediaPipePoseEstimator`).
- **Presentation Layer**: SwiftUI views and ViewModels driving the UI.
- **Core**: Shared utilities, error handling, and extensions.

## 🛠 Prerequisites

- **Xcode 14.0+**
- **iOS 15.0+** Device (Simulator does not support Camera)
- **CocoaPods**
- **Git LFS** (Recommended for large model files)

## 🏁 Getting Started

1. **Clone the repository**
    ```bash
    git clone https://github.com/Bruceyang5049/Apex-iOS.git
    cd Apex-iOS
    ```

2.  **Install Dependencies**
    ```bash
    pod install
    ```

3.  **Open the Workspace**
    Open `Apex.xcworkspace` (NOT the `.xcodeproj` file).

4.  **Add Model File**
    Ensure `pose_landmarker_full.task` is added to the project bundle resources.
    > *Note: Due to licensing, the model file might not be included in the repo. Download it from Google MediaPipe Tasks.*

5.  **Run on Device**
    Connect your iPhone, select your development team in Signing & Capabilities, and hit Run.

## 📂 Project Structure

```
Apex/
├── App/                  # App Entry & DI Container
├── Core/                 # Utilities & Error Handling
│   └── Filters/          # 🆕 One Euro Filter for data smoothing
├── Domain/               # Entities & Interfaces (Business Logic)
│   ├── Entities/         # 🆕 BiomechanicsMetrics, PoseLandmark
│   └── Services/         # 🆕 BiomechanicsAnalyzer, CalibrationManager
├── Data/                 # Concrete Implementations (MediaPipe, etc.)
├── Features/             # UI Modules (ServeAnalysis, etc.)
│   └── ServeAnalysis/
│       ├── Views/        # 🆕 CalibrationView, MetricsOverlayView
│       └── ViewModels/
└── Services/             # Infrastructure Services (Camera, etc.)
```

## 📚 Documentation
- [PRD v2.0](./PRD_v2.0.md) - Product Requirements Document with v2.0 roadmap
- [Biomechanics Implementation](./BIOMECHANICS_IMPLEMENTATION.md) - Detailed technical implementation
- [API Examples](./API_EXAMPLES.md) - Code usage examples and patterns
- [Testing Guide](./TESTING_GUIDE.md) - Testing procedures and validation criteria
- [PRD v1.0](./PRD.md) - Original MVP requirements (Chinese)

## 🤝 Contributing

This project is currently in the **MVP Phase**. Contributions are welcome!

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

**APEX Team** | *Bruce*
