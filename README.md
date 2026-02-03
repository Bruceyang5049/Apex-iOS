# APEX: AI Tennis Performance Analyzer

[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-v3.0%20Released-brightgreen.svg)]()

> **APEX** is an iOS application designed to democratize professional tennis coaching using advanced computer vision and biomechanics analysis.

---

## 🎉 v3.0 Update - Enhanced UI & Data Management Released!

**Release Date**: February 3, 2026

### ✨ What's New in v3.0

- ✅ **Session History View** (520 lines)
    - Sortable session list (date, quality score, duration)
    - Filterable by performance level (excellent/good/needs improvement)
    - Swipe actions for delete and JSON export
    - Detailed session view with phase timeline and feedback history

- ✅ **Expandable Feedback Card System** (290 lines)
    - Beautiful card-based presentation of AI coaching feedback
    - Expandable design showing severity, category, and actionable tips
    - Impact visualization with progress bar
    - Batch viewer with category filtering

- ✅ **4-Phase Progress Indicator** (370 lines)
    - Real-time animated progress bar for serve phases
    - Phase timeline with event markers and duration labels
    - Compact badge variant for status display
    - Mini floating indicator with pulse animation

- ✅ **Integrated Dashboard**
    - New toolbar buttons: History (purple) & Feedback (blue)
    - Phase badge display during active analysis
    - Sheet modals for drill-down details

### 📚 Complete Feature Set (v1.0-v3.0)

**v1.0 Foundation**
- Real-time pose estimation using MediaPipe (33 landmarks)
- Core camera integration and video processing at 60 FPS

**v1.5 Biomechanics Engine** 
- One Euro Filter smoothing for 7 key metrics
- Height-based calibration system
- Elite performance benchmarking

**v2.0 Analysis & Persistence**
- Serve phase detection (4-stage recognition)
- AI-powered natural language feedback generation
- SwiftData-based session persistence
- Performance monitoring dashboard with FPS tracking

**v3.0 User Experience** (🆕)
- Comprehensive session history management
- Visual feedback presentation system
- Phase progress tracking and visualization

---

## 📋 Table of Contents

- [APEX: AI Tennis Performance Analyzer](#apex-ai-tennis-performance-analyzer)
  - [📋 Table of Contents](#-table-of-contents)
  - [🚀 Overview](#-overview)
### Real-time Analysis
- **Pose Estimation**: MediaPipe Pose (33-landmark model) at 60 FPS with 3D world coordinates
- **Biomechanics Metrics**: 7 key measurements including knee flexion, hip-shoulder separation, contact height, wrist velocity
- **One Euro Filter**: Adaptive smoothing to reduce jitter while maintaining responsiveness
- **Phase Detection**: Automatic 4-stage serve recognition (preparation → loading → contact → follow-through)

### User Experience
- **Session History**: Browse, sort, filter, and export past analysis sessions
- **AI Feedback Cards**: Expandable coaching suggestions with severity levels and actionable tips
- **Phase Progress Visualization**: Real-time animated progress indicators and timeline
- **Performance Dashboard**: FPS tracking, inference latency monitoring, optimization recommendations

### Data Management
- **SwiftData Persistence**: Full session history with biomechanics, feedback, and user ratings
- **JSON Export**: Export sessions for analysis in external tools
- **User Calibration**: Height-based pixel-to-meter conversion with metric/imperial support
- **Privacy First**: All processing happens on-device; no video uploaded to cloud
- **High Performance**: Optimized for Apple Neural Engine (ANE) with `AsyncStream` concurrency
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
    Connect your iPhone, s        # App Entry & Dependency Injection
│   └── ApexApp.swift             # Main app entry point with ModelContext setup
├── Core/                         # Utilities & Error Handling
│   ├── Errors/
│   │   └── AppError.swift        # Custom error types
│   └── Filters/
│       └── OneEuroFilter.swift   # Smoothing algorithm for landmarks
├── Domain/                       # Entities & Interfaces (Clean Architecture)
│   ├── Entities/
│   │   ├── PoseLandmark.swift
│   │   ├── BiomechanicsMetrics.swift
│   │   ├── ServePhase.swift
│   │   ├── FeedbackItem.swift
│   │   ├── AnalysisSession.swift (SwiftData @Model)
│   │   └── ServePhaseEvent.swift
│   └── 3.0](./PRD.md) - Product Requirements Document with complete roadmap (Chinese)
- [v3.0 Release Summary](./RELEASE_v3.0_SUMMARY.md) - Comprehensive v3.0 feature overview and validation
- [v2.0 Release Summary](./RELEASE_v2.0_SUMMARY.md) - Complete v2.0 feature list and architecture
- [Biomechanics Implementation](./BIOMECHANICS_IMPLEMENTATION.md) - Detailed v1.5 technical implementation
- [API Examples](./API_EXAMPLES.md) - Code usage examples and patterns
- [Testing Guide](./TESTING_GUIDE.md) - Testing procedures and validation criteria
│       ├── SessionRepository.swift
│       └── PerformanceMonitor.swift
├── Data/                         # Concrete Implementations
│   ├── MediaPipePoseEstimator.swift
│   ├── BiomechanicsAnalyzer.swift
│   ├── ServePhaseDetectorImpl.swift
│   ├── LLMFeedbackGenerator.swift
│   ├── SessionRepositoryImpl.swift
│   └── PerformanceMonitorImpl.swift
├── Features/                     # UI Modules (MVVM)
│   └── ServeAnalysis/
│       ├── Views/
│       │   ├── ServeAnalysisView.swift      # Main analysis interface
│       │   ├── CameraPreviewView.swift      # Video stream display
│       │   ├── PermissionsView.swift        # Camera permission prompt
│       │   ├── PoseOverlayView.swift        # Skeleton visualization
│       │   ├── SessionHistoryView.swift     # 🆕 v3.0 Session browser
│       │   ├── FeedbackCardView.swift       # 🆕 v3.0 Feedback cards
│       │   ├── PhaseIndicatorView.swift     # 🆕 v3.0 Phase progress
│       │   ├── CalibrationView.swift        # Height calibration (v1.5)
│       │   └── MetricsOverlayView.swift     # Real-time metric display
│       └── ViewModels/
│           └── ServeAnalysisViewModel.swift # State management & logic
└── Services/                     # Infrastructure
    └── Camera/
        └── CameraManager.swift   # AVFoundation wrappernager
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
