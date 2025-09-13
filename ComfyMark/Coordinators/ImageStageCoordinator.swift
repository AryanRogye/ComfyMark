//
//  ImageStageCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/12/25.
//

import AppKit
import Cocoa
import SwiftUI
import Combine

@MainActor
final class ImageStageCoordinator {
    
    var imageStageScreen        : NSPanel!
    private var targetScreen    : NSScreen?
    private var stageVM         : ImageStageViewModel
    
    private var cancellables    : Set<AnyCancellable> = []
    private var appSettings     : AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        stageVM = ImageStageViewModel()
        stageVM.onExit = { [weak self] in
            guard let self = self else { return }
            self.hide()
        }
        
        setupOverlay(side: appSettings.screenshotSide)
        
        appSettings.$screenshotSide
            .sink { [weak self] side in
                guard let self = self else { return }
                self.imageStageScreen?.orderOut(nil)
                self.imageStageScreen?.close()
                self.setupOverlay(side: side)
            }
            .store(in: &cancellables)
    }
    
    public func setupOverlay(side: ImageStagerSide) {
        
        guard let screen = ScreenshotService.screenUnderMouse() else {
            print("Cant SetupOverlay, No screen")
            return
        }
        self.targetScreen = screen
        

        /// Should Be Bottom Right
        let leftPadding     : CGFloat = 20
        let bottomPadding   : CGFloat = 20
        
        let height : CGFloat = 150
        let width  : CGFloat = 150
        
        var x      : CGFloat = 0 + leftPadding
        let y      : CGFloat = 0 + bottomPadding
        
        print("Setting Up Overlay With: \(side)")
        if side == .right {
            x = screen.visibleFrame.width - (width + leftPadding)
        }
        
        let contentRect = CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
        
        imageStageScreen = FocusablePanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        imageStageScreen.setFrame(contentRect, display: true)
        /// Allow content to draw outside panel bounds
        imageStageScreen.contentView?.wantsLayer = true
        
        imageStageScreen.registerForDraggedTypes([.fileURL])
        imageStageScreen.title = "ComfyMark"
        
        let screenSaverRaw = CGWindowLevelForKey(.overlayWindow)
        imageStageScreen.level = NSWindow.Level(rawValue: Int(screenSaverRaw))
        imageStageScreen.ignoresMouseEvents = true

        imageStageScreen.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        imageStageScreen.isMovableByWindowBackground = false
        imageStageScreen.backgroundColor = .clear
        imageStageScreen.isOpaque = false
        imageStageScreen.hasShadow = false
        
        let hostingController = NSHostingController(
            rootView: ImageStager(
                stageVM: stageVM
            )
        )
        
        let view = hostingController.view
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        imageStageScreen.contentView = view
        // Ensure key events route into SwiftUI hosting view
        imageStageScreen.initialFirstResponder = view
        self.hide()
    }
    
    // MARK: - Show Hide Overlay
    public func show(with image: CGImage, onImageTapped: @escaping () -> Void) {
        if self.imageStageScreen == nil {
            setupOverlay(side: appSettings.screenshotSide)
            imageStageScreen?.layoutIfNeeded()
        }
        guard let imageStageScreen = self.imageStageScreen else {
            print("Cant Show, Overlay is nil")
            return
        }
        
        // Get the current screen under mouse when showing
        guard let currentScreen = ScreenshotService.screenUnderMouse() else {
            print("Can't show, no screen under mouse")
            return
        }
        
        // If we need to recreate the overlay for a different screen
        if targetScreen != currentScreen {
            targetScreen = currentScreen
            setupOverlay(side: appSettings.screenshotSide)
        }
        
        stageVM.onImageTapped = onImageTapped
        stageVM.image = image
        imageStageScreen.orderFront(nil)
        imageStageScreen.makeFirstResponder(imageStageScreen.contentView)
        imageStageScreen.ignoresMouseEvents = false
        if let contentView = imageStageScreen.contentView {
            imageStageScreen.invalidateCursorRects(for: contentView)
        }
    }
    
    public func hide() {
        guard let imageStageScreen = imageStageScreen else {
            print("Cant Hide, Overlay is nil")
            return
        }
        
        if imageStageScreen.isVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                self.stageVM.image = nil
                self.imageStageScreen?.orderOut(nil)
            }
        }
    }
    
}
