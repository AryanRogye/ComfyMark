//
//  AppCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

@MainActor
class AppCoordinator {
    
    private var menuBarCoordinator = MenuBarCoordinator()
    
    private lazy var windowCoordinator = WindowCoordinator()
    private var settingsCoordinator : SettingsCoordinator!
    
    init() {
        self.settingsCoordinator = SettingsCoordinator(windows: windowCoordinator)
        
        menuBarCoordinator.start(onSettingsTapped: {
            self.settingsCoordinator.showSettings()
        })
    }
}
