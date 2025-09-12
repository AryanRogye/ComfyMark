//
//  ScreenshotHotkeySettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI
import KeyboardShortcuts

struct ScreenshotHotkeySettings: View {
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Screenshot Hotkey")
            Spacer()
            KeyboardShortcuts.Recorder("", name: .ComfyMarkScreenshot)
        }
        .padding(.horizontal)
    }
}
