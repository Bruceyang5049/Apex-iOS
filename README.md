# APEX: AI Tennis Performance Analyzer

[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-lightgrey.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-MVP%20Development-yellow.svg)]()

> **APEX** is an iOS application designed to democratize professional tennis coaching using advanced computer vision and biomechanics analysis.

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
- **Biomechanics Feedback**: (In Progress) Instant feedback on serve technique based on elite reference models.
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

1.  **Clone the repository**
    ```bash
    git clone https://github.com/your-username/apex-ios.git
    cd apex-ios
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
├── Domain/               # Entities & Interfaces (Business Logic)
├── Data/                 # Concrete Implementations (MediaPipe, etc.)
├── Features/             # UI Modules (ServeAnalysis, etc.)
│   └── ServeAnalysis/
│       ├── Views/
│       └── ViewModels/
└── Services/             # Infrastructure Services (Camera, etc.)
```

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
