//
//  SettingsViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import Combine
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    
    @AppStorage("lastSettingsTab") private var lastTab: String = SettingsTab.general.rawValue

    @Published var selectedTab: SettingsTab = .general {
        didSet { lastTab = selectedTab.rawValue }
    }
    
    let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        self.selectedTab = SettingsTab(rawValue: lastTab) ?? .general
    }
}
