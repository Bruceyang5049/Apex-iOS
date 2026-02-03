//
//  ApexApp.swift
//  Apex
//
//  Created by Yang Paul on 12/14/25.
//

import SwiftUI
import SwiftData

@main
struct ApexApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: AnalysisSession.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
