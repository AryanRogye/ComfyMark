//
//  GeneralSettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import SwiftUI
import KeyboardShortcuts

struct GeneralSettings: View {
    
    @EnvironmentObject var generalVM : GeneralViewModel
    
    var body: some View {
        SettingsContainerView {
            hotkeySettings
            basicSettings
        }
    }
    
    private var hotkeySettings: some View {
        SettingsSection {
            KeyboardShortcuts.Recorder("Take Screen Shot:", name: .ComfyMarkScreenshot)
        }
    }
    
    private var basicSettings: some View {
        SettingsSection {
            showDockIcon
            Divider().groupBoxStyle()
            launchAtLogin
        }

    }
    
    private var showDockIcon: some View {
        HStack {
            
            Text("Show Dock Icon")
            
            Spacer()
            
            Toggle("Show Dock Icon", isOn: $generalVM.appSettings.showDockIcon)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
    
    private var launchAtLogin: some View {
        HStack {
            
            Text("Launch at Login")
            
            Spacer()
            
            Toggle("Launch at Login", isOn: $generalVM.appSettings.launchAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
}
