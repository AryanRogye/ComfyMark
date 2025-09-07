//
//  KeyboardShortcut.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let ComfyMarkScreenshot = Self("ComfyMarkScreenshot")
}

@MainActor
final class HotKeyCoordinator {
    
    private(set) var comfyMarkScreenshot   : KeyboardShortcuts.Name
    
    init(
        onHotKeyDown: @escaping () -> Void,
        onHotKeyUp: @escaping () -> Void
    ) {
        self.comfyMarkScreenshot = .ComfyMarkScreenshot
        
        KeyboardShortcuts.onKeyDown(for: self.comfyMarkScreenshot) {
            onHotKeyUp()
        }
        KeyboardShortcuts.onKeyUp(for: self.comfyMarkScreenshot) {
            onHotKeyDown()
        }
    }
}
