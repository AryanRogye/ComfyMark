//
//  ComfyMarkApp.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

@main
struct ComfyMarkApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .destroyViewWindow()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { appDelegate.openSettings?() }
                    .keyboardShortcut(",", modifiers: .command)
                    .disabled(appDelegate.openSettings == nil)
            }
        }
    }
}
