//
//  SettingsCoordinator.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/24/25.
//

import SwiftUI

@MainActor
class SettingsCoordinator: ObservableObject {
    
    let windowCoordinator: WindowCoordinator
    
    init(windows: WindowCoordinator) {
        self.windowCoordinator = windows
    }
    
    func showSettings() {
        
        let view = SettingsView()
        
        windowCoordinator.showWindow(
            id: "settings",
            title: "Settings",
            content: view,
            size: NSSize(width: 800, height: 500),
            onOpen: { [weak self] in
                self?.windowCoordinator.activateWithRetry()
            },
            onClose: {
                NSApp.activate(ignoringOtherApps: false)
            })
    }    
}
