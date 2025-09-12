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
        
        self.selectionOverlayCoordinator = SelectionOverlayCoordinator(
            capture: { [weak self] rect, screen in
                guard let self = self else { return }
                self.takeScreenshotAndShow(rect: rect, on: screen)
            }
        )
        self.settingsCoordinator = SettingsCoordinator(
            windows: windowCoordinator,
            appSettings: appSettings
        )
        self.comfyMarkCoordinator = ComfyMarkCoordinator(
            windows: windowCoordinator
        )
        
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
                takeScreenshotAndShow()
            },
            onStartTappedImage: {[weak self] image, projectName in
                guard let self else { return }
                showImage(image, projectName: projectName)
            },
            onCrop: { [weak self] in
                guard let self = self else { return }
                self.selectionOverlayCoordinator.show()
            }
        )
    }
    
    private func showImage(_ image: CGImage, windowID: String = "comfymark-\(UUID().uuidString)") {
        self.comfyMarkCoordinator.showComfyMark(
            with: image,
            export: self.export,
            saving: self.saving,
            screenshotManager: screenshotManager,
            /// Update Last Render Time
            onLastRenderTimeUpdated: { [weak self] renderTimeMs in
                guard let self = self else { return }
                self.menuBarCoordinator.updateRenderTime(renderTimeMs)
            },
            windowID: windowID
        )
    }
    
    private func showImage(_ image: CGImage, projectName: String) {
        let windowID: String = "comfymark-\(UUID().uuidString)"
        self.comfyMarkCoordinator.showComfyMark(
            with: image,
            export: self.export,
            saving: self.saving,
            screenshotManager: screenshotManager,
            /// Update Last Render Time
            onLastRenderTimeUpdated: { [weak self] renderTimeMs in
                guard let self = self else { return }
                self.menuBarCoordinator.updateRenderTime(renderTimeMs)
            },
            windowID: windowID,
            projectName: projectName
        )
    }
    
}


// MARK: - Helpers
extension AppCoordinator {
    /// Function To Take Screenshot Of Specified Screen, this is cuz
    /// When we decide what to show the overlay on THAT is the screen
    /// and if the user changes the mouse, then this wont be valid anymore
    /// so we have to always remeber what screen we're doing it on
    private func takeScreenshotAndShow(rect: CGRect, on screen: NSScreen) {
        Task {
            guard let image = await self.screenshots.takeScreenshot(of: screen) else { return }
            
            // Map points (overlay) -> pixels (screenshot) using actual image-to-screen ratio.
            let clamped = Self.pixelCropRect(
                fromPoints: rect,
                image: image,
                screenSizePoints: screen.frame.size
            )
            
            /// If We Have Bad Size
            guard clamped.width > 0, clamped.height > 0 else {
                showImage(image)
                return
            }
            
            if let cropped = image.cropping(to: clamped) {
                /// If Valid Crop Show with rect or we thought
                showImage(cropped)
            } else {
                /// Not Valid
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
    
    static func pixelCropRect(fromPoints r: CGRect, image: CGImage, screenSizePoints: CGSize) -> CGRect {
        
        func clamp(_ r: CGRect, to bounds: CGRect) -> CGRect {
            let x = max(bounds.minX, min(r.minX, bounds.maxX))
            let y = max(bounds.minY, min(r.minY, bounds.maxY))
            let w = max(0, min(r.width, bounds.maxX - x))
            let h = max(0, min(r.height, bounds.maxY - y))
            return CGRect(x: x, y: y, width: w, height: h)
        }

        
        let imageSize: CGSize = CGSize(width: image.width, height: image.height)
        
        let sx = imageSize.width / screenSizePoints.width
        let sy = imageSize.height / screenSizePoints.height
        let x = r.origin.x * sx
        let y = r.origin.y * sy
        let w = r.size.width * sx
        let h = r.size.height * sy
        
        
        let pixelRect = CGRect(x: floor(x), y: floor(y), width: floor(w), height: floor(h))
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let clamped = clamp(pixelRect, to: bounds)

        return clamped
    }
}
