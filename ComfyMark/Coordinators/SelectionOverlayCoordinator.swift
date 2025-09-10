//
//  CursorManager.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

import AppKit
import SwiftUI

/**
 * Custom NSPanel subclass that can become key and main window.
 * Enables proper focus and interaction handling.
 */
class FocusablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    override var canBecomeMain: Bool {
        return true
    }
}

final class SelectionOverlayCoordinator {
    
    var overlayScreen : NSPanel!
    let selectionOverlayVM : SelectionOverlayViewModel
    
    init() {
        /// Setup OverlayViewModel Closures
        self.selectionOverlayVM = SelectionOverlayViewModel()
        selectionOverlayVM.onExit = self.hide
        selectionOverlayVM.onSelectionFinished = { rect in
            print("Finished On Rect: \(rect)")
        }
        
        setupOverlay()
    }
    
    public func setupOverlay() {
        
        guard let screen = ScreenshotService.screenUnderMouse() else {
            print("Cant SetupOverlay, No screen")
            return
        }
        
        overlayScreen = FocusablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        overlayScreen.setFrame(screen.frame, display: true)
        /// Allow content to draw outside panel bounds
        overlayScreen.contentView?.wantsLayer = true
        
        overlayScreen.registerForDraggedTypes([.fileURL])
        overlayScreen.title = "ComfyNotch"
        overlayScreen.acceptsMouseMovedEvents = true
        
        let screenSaverRaw = CGWindowLevelForKey(.screenSaverWindow)
        overlayScreen.level = NSWindow.Level(rawValue: Int(screenSaverRaw))
        
        overlayScreen.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayScreen.isMovableByWindowBackground = false
        overlayScreen.backgroundColor = .clear
        overlayScreen.isOpaque = false
        overlayScreen.hasShadow = false
        
        let view: NSView = CrosshairHostingView(
            rootView: SelectionOverlay(
                selectionOverlayVM: selectionOverlayVM
            )
        )
        
        /// Allow hosting view to overflow
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        
        overlayScreen.contentView = view
        // Ensure key events route into SwiftUI hosting view
        overlayScreen.initialFirstResponder = view
        self.hide()
    }
    
    // MARK: - Show Hide Overlay
    public func show() {
        if self.overlayScreen == nil {
            setupOverlay()
            overlayScreen?.layoutIfNeeded()
        }
        guard let overlayScreen = self.overlayScreen else {
            print("Cant Show, Overlay is nil")
            return
        }
        
        if !overlayScreen.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            overlayScreen.makeKeyAndOrderFront(nil)
            overlayScreen.makeFirstResponder(overlayScreen.contentView)
            overlayScreen.ignoresMouseEvents = false
            NSCursor.crosshair.set()
            if let contentView = overlayScreen.contentView {
                overlayScreen.invalidateCursorRects(for: contentView)
                DispatchQueue.main.async {
                    overlayScreen.invalidateCursorRects(for: contentView)
                    NSCursor.crosshair.set()
                }
            }
        }
    }
    
    public func hide() {
        guard let overlayScreen = overlayScreen else {
            print("Cant Hide, Overlay is nil")
            return
        }
        
        if overlayScreen.isVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self = self else { return }
                self.overlayScreen?.orderOut(nil)
                
                self.selectionOverlayVM.dragStart = nil
                self.selectionOverlayVM.dragCurrent = nil
                
                NSCursor.arrow.set()
            }
        }
    }
}
