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
            
            Divider().groupBoxStyle()
            
            DismissScreenshotTimerSlider(
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

// MARK: - Slider For Timer
struct DismissScreenshotTimerSlider: View {
    
    @ObservedObject var appSettings : AppSettings
    
    var disabled : Bool {
        
        /// Disabled IF
        /// dismissStageBehavior is not timer
        appSettings.dismissStagerBehavior != .timer
        /// or we are not allowing the native screenshot behavior
        || !appSettings.allowNativeScreenshotBehavior
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("Dismiss Timer Duration")
            Slider(value: $appSettings.dismissStagerTimer, in: 5...30, step: 1)
                .accessibilityLabel("Timer duration in seconds")
                .disabled(disabled)
                /// Simulating HStack Spacing with 12
                .padding(.leading, 32)
            Text("\(Int(appSettings.dismissStagerTimer))")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                /// Simulating HStack Spacing with 8
                .padding(.leading, 8)
            Text("s")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                /// Simulating Nice Spacing with 2
                .padding(.leading, 2)
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
