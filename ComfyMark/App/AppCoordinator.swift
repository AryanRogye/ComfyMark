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
    private var comfyMarkCoordinator : ComfyMarkCoordinator!
    
    /// Protocols/Services
    private var screenshots : ScreenshotProviding
    
    init(
        screenshots: ScreenshotProviding
    ) {
        self.screenshots = screenshots
        self.settingsCoordinator = SettingsCoordinator(windows: windowCoordinator)
        self.comfyMarkCoordinator = ComfyMarkCoordinator(windows: windowCoordinator)
        
        menuBarCoordinator.start(
            onSettingsTapped: {
                [weak self] in self?.settingsCoordinator.showSettings()
            },
            onStartTapped: { [weak self] in
                guard let self else { return }
                Task {
                    let image = try await self.screenshots.takeScreenshot()
                    self.comfyMarkCoordinator.showComfyMark(with: image)
                }
            })
    }
}
