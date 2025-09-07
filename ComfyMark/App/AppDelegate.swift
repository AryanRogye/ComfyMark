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
    
    @MainActor
    override init() {
        
        let screenshots = ScreenshotService()
        let export = ExportService()
        let saving = SavingService()
        
        let screenshotManager = ScreenshotManager(saving: saving)
        
        
        appCoordinator = AppCoordinator(
            screenshots: ScreenshotService(),
            export: export,
            saving: saving,
            screenshotManager: screenshotManager
        )
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
