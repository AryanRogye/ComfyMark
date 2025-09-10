//
//  SelectionOverlayHotkeySettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

import SwiftUI
import KeyboardShortcuts

struct SelectionOverlayHotkeySettings: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("Selection Overlay Hotkey")
            Spacer()
            KeyboardShortcuts.Recorder("", name: .ComfyMarkSelectionOverlay)
        }
        .padding(.horizontal)
    }
}
