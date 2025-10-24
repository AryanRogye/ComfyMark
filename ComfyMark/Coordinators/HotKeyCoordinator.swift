//
//  KeyboardShortcut.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let ComfyMarkScreenshot = Self("ComfyMarkScreenshot")
    static let ComfyMarkSelectionOverlay = Self("ComfyMarkSelectionOverlay")
}

@MainActor
final class HotKeyCoordinator {
    
    private(set) var comfyMarkScreenshot   : KeyboardShortcuts.Name
    private(set) var comfyMarkSelectionOverlay : KeyboardShortcuts.Name
    
    init(
        onHotKeyDown: @escaping () -> Void,
        onHotKeyUp: @escaping () -> Void,
        onSelectionOverlayDown: @escaping () -> Void,
        onSelectionOverlayUp: @escaping () -> Void
    ) {
        self.comfyMarkScreenshot = .ComfyMarkScreenshot
        self.comfyMarkSelectionOverlay = .ComfyMarkSelectionOverlay
        
        
        // MARK: - Regular Screenshot
        KeyboardShortcuts.onKeyDown(for: self.comfyMarkScreenshot) {
            onHotKeyUp()
        }
        KeyboardShortcuts.onKeyUp(for: self.comfyMarkScreenshot) {
            onHotKeyDown()
        }
        
        // MARK: - Setup Selection
        KeyboardShortcuts.onKeyUp(for: self.comfyMarkSelectionOverlay) {
            onSelectionOverlayUp()
        }
        KeyboardShortcuts.onKeyDown(for: self.comfyMarkSelectionOverlay) {
            onSelectionOverlayDown()
        }
    }
}
