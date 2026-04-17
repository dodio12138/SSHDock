//
//  SSHDockApp.swift
//  SSHDock
//
//  Created by LevyZhang on 16/04/2026.
//

import SwiftUI
import SwiftData

@main
struct SSHDockApp: App {
    @State private var menuBarController: MenuBarController?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            ConnectionItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema 不兼容（如字段变更）时删除旧 store 并重建，开发阶段可接受
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storeURL = appSupport.appending(path: "default.store")
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if menuBarController == nil {
                        menuBarController = MenuBarController(modelContainer: sharedModelContainer)
                    }
                }
        }
        .modelContainer(sharedModelContainer)

        // macOS 设置窗口（⌘,）
        Settings {
            SettingsView()
        }
    }
}
