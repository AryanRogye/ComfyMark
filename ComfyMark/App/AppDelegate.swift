//
//  AppDelegate.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let appCoordinator: AppCoordinator
    @MainActor var openSettings: (() -> Void)?
    
    @MainActor
    override init() {
        
        let screenshots = ScreenshotService()
        let export = ExportService()
        let saving = SavingService()
        
        let screenshotManager = ScreenshotManager(saving: saving)
        
        appCoordinator = AppCoordinator(
            screenshots: screenshots,
            export: export,
            saving: saving,
            screenshotManager: screenshotManager,
        )
        openSettings = appCoordinator.openSettings
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
