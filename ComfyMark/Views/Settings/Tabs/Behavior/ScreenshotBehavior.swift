//
//  ScreenshotBehavior.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/13/25.
//

import SwiftUI

struct ScreenshotBehaviorSettings: View {
    
    var body: some View {
        SettingsSection("Screenshot Behavior") {
            ScreenshotPickSide()
        }
    }
}

struct ScreenshotPickSide: View {
    
    @EnvironmentObject var behaviorVM : BehaviorViewModel
    
    var body: some View {
        HStack {
            Text("Pick Screenshot Side")
            Spacer()
            Picker("", selection: $behaviorVM.appSettings.screenshotSide) {
                ForEach(ImageStagerSide.allCases, id: \.self) { side in
                    Text(side.rawValue).tag(side)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
}
