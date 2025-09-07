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
    let appSettings      : AppSettings
    
    var settingsVM: SettingsViewModel?
    var generalVM : GeneralViewModel?
    var behaviorVM: BehaviorViewModel?
    
    init(windows: WindowCoordinator, appSettings: AppSettings) {
        self.windowCoordinator = windows
        self.appSettings = appSettings
    }
    
    func showSettings() {
        
        settingsVM = SettingsViewModel(appSettings: appSettings)
        generalVM  = GeneralViewModel(appSettings: appSettings)
        behaviorVM = BehaviorViewModel(appSettings: appSettings)
        
        guard let settingsVM = settingsVM else { return }
        guard let generalVM  = generalVM  else { return }
        guard let behaviorVM = behaviorVM else { return }
        
        let view = SettingsView(
            settingsVM: settingsVM,
            generalVM: generalVM,
            behaviorVM: behaviorVM
        )
        
        windowCoordinator.showWindow(
            id: "settings",
            title: "Settings",
            content: view,
            size: NSSize(width: 800, height: 500),
            onOpen: { [weak self] in
                self?.appSettings.isSettingsWindowOpen = true
                self?.windowCoordinator.activateWithRetry()
            },
            onClose: { [weak self] in
                self?.appSettings.isSettingsWindowOpen = false
                NSApp.activate(ignoringOtherApps: false)
            })
    }    
}
