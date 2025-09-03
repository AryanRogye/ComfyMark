//
//  SettingsTab.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general        = "General"
    case about          = "About"
    
    var color: Color {
        switch self {
        case .general:
            return Color.primary.opacity(0.15) // neutral backdrop
        case .about:
            return Color.primary.opacity(0.15) // neutral backdrop
        }
    }
    var titleColor: Color {
        switch self {
        case .general:
            return Color.primary.opacity(0.75) // neutral backdrop
        case .about:
            return Color.primary.opacity(0.75) // neutral backdrop
        }
    }
    
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .general:      GeneralSettings()
        case .about:        AboutView()
        }
    }
    
    /// Gives SystemName
    var icon: String {
        switch self {
        case .general:      return "gearshape"
        case .about:        return "info.circle"
        }
    }
}
