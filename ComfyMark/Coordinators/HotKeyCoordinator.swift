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
    
    init() {
        self.comfyMarkScreenshot = .ComfyMarkScreenshot
        
        KeyboardShortcuts.onKeyDown(for: self.comfyMarkScreenshot) {
            print("Took Screenshot")
        }
        KeyboardShortcuts.onKeyUp(for: self.comfyMarkScreenshot) {
            print("Took Screenshot Off")
        }
    }
}
