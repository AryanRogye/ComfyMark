//
//  SettingsView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var settingsVM: SettingsViewModel
    @ObservedObject var generalVM: GeneralViewModel
    
    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            SettingsContent()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(settingsVM)
        .environmentObject(generalVM)
        .onAppear {
            onAppear()
        }
    }
    
    private func onAppear() {
        /// Make Sure That the Window is Above runs after 0.2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.activate(ignoringOtherApps: true)
            
            // Find window by title or identifier
            if let window = NSApp.windows.first(where: {
                $0.title.contains("Settings") || $0.identifier?.rawValue == "SettingsView"
            }) {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
    }
}


struct Sidebar: View {
    
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var selectedTab : SettingsTab = .general
    
    var body: some View {
        List(selection: $selectedTab) {
            Section {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Label {
                        Text(tab.rawValue)
                            .padding(.leading, 8)
                    } icon: {
                        Image(systemName: tab.icon)
                            .iconWithRectangle(
                                bg: tab.color
                            )
                    }
                }
            } header: {
                Text("ComfyMark")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 5)
            }
            .collapsible(false)
        }
        .scrollDisabled(true)
        .navigationSplitViewColumnWidth(200)
        /// Helps With Not Publishing View Updates
        .onAppear {
            selectedTab = settingsVM.selectedTab
        }
        .onChange(of: selectedTab) { _, newValue in
            settingsVM.selectedTab = newValue
        }
    }
}

struct SettingsContent: View {
    
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    var body: some View {
        settingsVM.selectedTab.view
    }
}
