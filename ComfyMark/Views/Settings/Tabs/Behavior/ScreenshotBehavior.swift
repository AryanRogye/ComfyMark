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
            
            /// Toggle For Screenshot Behavior
            AllowNativeScreenshotBehavior(
                appSettings: behaviorVM.appSettings
            )
            
            Divider().groupBoxStyle()
            
            /// Screenshot Side Picker
            ScreenshotPickSide(
                appSettings: behaviorVM.appSettings
            )
            
            Divider().groupBoxStyle()
            
            /// Dismiss Behavior For Screenshot
            DismissScreenshotStager(
                appSettings: behaviorVM.appSettings
            )
        }
    }
}

// MARK: - Main Allow Native Behavior
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

// MARK: - Dismiss Behavior Picker
struct DismissScreenshotStager: View {
    
    @ObservedObject var appSettings : AppSettings
    @State private var tempDismissStagerBehavior : DismissScreenshotOption = .timer

    var body: some View {
        HStack {
            Text("Dismiss Screenshot Timer")
            Spacer()
            Picker("", selection: $tempDismissStagerBehavior) {
                ForEach(DismissScreenshotOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .allowsHitTesting(appSettings.allowNativeScreenshotBehavior)
            .opacity(appSettings.allowNativeScreenshotBehavior ? 1.0 : 0.6)
            .onChange(of: tempDismissStagerBehavior) { _, value in
                appSettings.dismissStagerBehavior = value
            }
        }
        .padding(.horizontal)
        .onAppear {
            tempDismissStagerBehavior = appSettings.dismissStagerBehavior
        }
    }
}

// MARK: - Pick Side Picker
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
