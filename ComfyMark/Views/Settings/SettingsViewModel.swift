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
    
    @Published var selectedTab: SettingsTab = .general
    let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
}
