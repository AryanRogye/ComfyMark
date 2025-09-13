//
//  ScreenshotBehavior.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/13/25.
//

import SwiftUI

struct ScreenshotBehaviorSettings: View {
    
    @EnvironmentObject var behaviorVM : BehaviorViewModel
    
    var body: some View {
        SettingsSection("Screenshot Behavior") {
            AllowNativeScreenshotBehavior(
                appSettings: behaviorVM.appSettings
            )
            
            Divider().groupBoxStyle()
            
            if behaviorVM.appSettings.allowNativeScreenshotBehavior {
                ScreenshotPickSide(
                    appSettings: behaviorVM.appSettings
                )
            }
        }
    }
}

struct AllowNativeScreenshotBehavior: View {
    
    @ObservedObject var appSettings : AppSettings

    var body: some View {
        HStack {
            Text("Allow Native Screenshot Behavior")
            Spacer()
            Toggle("", isOn: $appSettings.allowNativeScreenshotBehavior)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
}

struct ScreenshotPickSide: View {
    
    @ObservedObject var appSettings : AppSettings
    @State private var tempSelection : ImageStagerSide = .left
    
    var body: some View {
        HStack {
            Text("Pick Screenshot Side")
            Spacer()
            Picker("", selection: $tempSelection) {
                ForEach(ImageStagerSide.allCases, id: \.self) { side in
                    Text(side.rawValue).tag(side)
                }
            }
            .pickerStyle(.segmented)
            .allowsHitTesting(appSettings.allowNativeScreenshotBehavior)
            .opacity(appSettings.allowNativeScreenshotBehavior ? 1.0 : 0.6)
            .onChange(of: tempSelection) { _, newValue in
                appSettings.screenshotSide = newValue
            }
        }
        .padding(.horizontal)
        .onAppear {
            tempSelection = appSettings.screenshotSide
        }
    }
}
