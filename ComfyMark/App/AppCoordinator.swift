//
//  AppCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import CoreGraphics
import Foundation
import AppKit

@MainActor
class AppCoordinator {
    
    private var menuBarCoordinator = MenuBarCoordinator()
    
    /// Coordinators
    private lazy var windowCoordinator      = WindowCoordinator()
    private var hotkeyCoordinator           : HotKeyCoordinator!
    private var settingsCoordinator         : SettingsCoordinator!
    private var comfyMarkCoordinator        : ComfyMarkCoordinator!
    private var selectionOverlayCoordinator : SelectionOverlayCoordinator!
    private var imageStageCoordinator       : ImageStageCoordinator!
    
    /// Protocols/Services
    private var screenshots : ScreenshotProviding
    private var export      : ExportProviding
    private var saving      : SavingProviding
    
    /// Managers
    private var screenshotManager : ScreenshotManager
    
    /// App Settings
    private let appSettings = AppSettings()
    
    var openSettings: (() -> Void)?
    
    init(
        screenshots         : ScreenshotProviding,
        export              : ExportProviding,
        saving              : SavingProviding,
        screenshotManager   : ScreenshotManager,
    ) {
        self.screenshots = screenshots
        self.export      = export
        self.saving      = saving
        self.screenshotManager = screenshotManager
        
        /// Configure Coordinators
        self.configureSelectionOverlayCoordinator()
        self.configureImageStageCoordinator()
        self.configureSettingsCoordinator()
        self.configureComfyMarkCoordinator()
        self.configureHotKeyCoordinator()
        
        openSettings = {
            /// If Overlay Screen is Showing, Hide It
            if self.selectionOverlayCoordinator.overlayScreen.isVisible {
                self.selectionOverlayCoordinator.hide()
            }
            
            self.settingsCoordinator.showSettings()
        }
        
        /// Starting Our Menu Bar, with Closures, for what happens when we:
        /// Tap On Settings
        /// Tap On Start
        /// Tap on Start with a Image selected in History
        /// Tap on Crop
        menuBarCoordinator.start(
            screenshotManager: screenshotManager,
            appSettings: appSettings,
            onSettingsTapped: { [weak self] in
                guard let self = self else { return }
                self.openSettings?()
            },
            onStartTapped: { [weak self] in
                guard let self else { return }
                takeScreenshotAndShow()
            },
            onStartTappedImage: {[weak self] image, projectName in
                guard let self else { return }
                openComfyMarkWindow(image, projectName: projectName)
            },
            onCrop: { [weak self] in
                guard let self = self else { return }
                self.selectionOverlayCoordinator.show()
            }
        )
    }
    
    // MARK: - HotKey Coordinator
    private func configureHotKeyCoordinator() {
        self.hotkeyCoordinator = HotKeyCoordinator(
            // Regular Screenshot
            onHotKeyDown: { [weak self] in
                guard let self = self else { return }
                self.takeScreenshotAndShow()
            },
            onHotKeyUp: {
                
            },
            /// Overlay Selection Screenshot
            onSelectionOverlayDown: { [weak self] in
                guard let self = self else { return }
                self.selectionOverlayCoordinator.show()
            },
            onSelectionOverlayUp: {
            }
        )
    }
    
    // MARK: - ComfyMark Coordinator
    private func configureComfyMarkCoordinator() {
        self.comfyMarkCoordinator = ComfyMarkCoordinator(
            windows: windowCoordinator
        )
    }
    
    // MARK: - Settings Coordinator
    private func configureSettingsCoordinator() {
        self.settingsCoordinator = SettingsCoordinator(
            windows: windowCoordinator,
            appSettings: appSettings
        )
    }
    
    // MARK: -
    private func configureImageStageCoordinator() {
        self.imageStageCoordinator = ImageStageCoordinator(
            appSettings: appSettings
        )
    }

    // MARK: - Selection Coordinator
    private func configureSelectionOverlayCoordinator() {
        self.selectionOverlayCoordinator = SelectionOverlayCoordinator(
            capture: { [weak self] rect, screen in
                guard let self = self else { return }
                self.takeScreenshotAndShow(rect: rect, on: screen)
            }
        )
    }
}

// MARK: - Screenshot
extension AppCoordinator {
    private func showImage(_ image: CGImage) {
        /// Decide How We Want to show The Image, Native way or Fullscreen
//        openComfyMarkWindow(image)
        stageImage(image)
    }
    /// Function To Take Screenshot Of Specified Screen, this is cuz
    /// When we decide what to show the overlay on THAT is the screen
    /// and if the user changes the mouse, then this wont be valid anymore
    /// so we have to always remeber what screen we're doing it on
    private func takeScreenshotAndShow(rect: CGRect, on screen: NSScreen) {
        Task {
            if let image = await self.screenshots.takeScreenshot(of: screen, croppingTo: rect) {
                showImage(image)
            }
        }
    }
    
    /// Function takes a screenshot and then shows
    private func takeScreenshotAndShow() {
        Task {
            if let image = await self.screenshots.takeScreenshot() {
                showImage(image)
            }
        }
    }    
}


// MARK: - Open Windows
extension AppCoordinator {
    private func stageImage(_ image: CGImage) {
        imageStageCoordinator.show(with: image, onImageTapped: { [weak self] in
            guard let self = self else { return }
            self.openComfyMarkWindow(image, side: appSettings.screenshotSide)
        })
    }
    private func openComfyMarkWindow(_ image: CGImage, projectName: String? = nil, side: ImageStagerSide? = nil) {
        /// Generate A Window ID
        let windowID: String = "comfymark-\(UUID().uuidString)"
        self.comfyMarkCoordinator.showComfyMark(
            with: image,
            export: self.export,
            saving: self.saving,
            screenshotManager: screenshotManager,
            /// Update Last Render Time, Shown in MenuBar
            onLastRenderTimeUpdated: { [weak self] renderTimeMs in
                guard let self = self else { return }
                self.menuBarCoordinator.updateRenderTime(renderTimeMs)
            },
            windowID: windowID,
            projectName: projectName,
            side: side
        )
    }
}
