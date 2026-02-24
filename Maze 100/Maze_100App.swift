//
//  Maze_100App.swift
//  Maze 100
//
//  Created by Dmitrii on 21.02.2026.
//

import SwiftUI

@main
struct Maze_100App: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        CrashReportingManager.shared.configure()
        AnalyticsManager.shared.track("app_launch")
    }
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
        .onChange(of: scenePhase) { _, phase in
            CrashReportingManager.shared.addBreadcrumb(
                category: "app_lifecycle",
                message: "Scene phase changed",
                metadata: ["phase": String(describing: phase)]
            )
        }
    }
}
