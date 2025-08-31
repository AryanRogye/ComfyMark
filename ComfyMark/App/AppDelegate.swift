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
        appCoordinator = AppCoordinator()
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
