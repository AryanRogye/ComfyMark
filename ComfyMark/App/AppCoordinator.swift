//
//  AppCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

@MainActor
class AppCoordinator {
    
    private var menuBarCoordinator = MenuBarCoordinator()
    
    /// Coordinators
    private lazy var windowCoordinator  = WindowCoordinator()
    private var hotkeyCoordinator       : HotKeyCoordinator!
    private var settingsCoordinator     : SettingsCoordinator!
    private var comfyMarkCoordinator    : ComfyMarkCoordinator!
    
    /// Protocols/Services
    private var screenshots : ScreenshotProviding
    private var export      : ExportProviding
    private var saving      : SavingProviding
    
    /// Managers
    private var screenshotManager : ScreenshotManager
    
    /// App Settings
    private let appSettings = AppSettings()
    
    init(
        screenshots         : ScreenshotProviding,
        export              : ExportProviding,
        saving              : SavingProviding,
        screenshotManager   : ScreenshotManager
    ) {
        self.screenshots = screenshots
        self.export      = export
        self.saving      = saving
        self.screenshotManager = screenshotManager
        
        self.settingsCoordinator = SettingsCoordinator(
            windows: windowCoordinator,
            appSettings: appSettings
        )
        
        self.comfyMarkCoordinator = ComfyMarkCoordinator(
            windows: windowCoordinator
        )
        
        
        self.hotkeyCoordinator = HotKeyCoordinator(
            onHotKeyDown: { [weak self] in
                guard let self = self else { return }
                self.takeScreenshot()
            },
            onHotKeyUp: {
                
            }
        )
        
        
        /// Starting Our Menu Bar, with Closures, for what happens when we:
        /// Tap On Settings
        /// And
        /// Tap On Start
        menuBarCoordinator.start(
            screenshotManager: screenshotManager,
            appSettings: appSettings,
            onSettingsTapped: { [weak self] in
                guard let self = self else { return }
                self.settingsCoordinator.showSettings()
            },
            onStartTapped: { [weak self] in
                guard let self else { return }
                takeScreenshot()
            })
    }
    
    private func takeScreenshot() {
        Task {
            let image = try await self.screenshots.takeScreenshot()
            self.comfyMarkCoordinator.showComfyMark(
                with: image,
                export: self.export,
                saving: self.saving,
                screenshotManager: screenshotManager,
                /// Update Last Render Time
                onLastRenderTimeUpdated: { [weak self] renderTimeMs in
                    guard let self = self else { return }
                    self.menuBarCoordinator.updateRenderTime(renderTimeMs)
                }
            )
        }
    }
}
