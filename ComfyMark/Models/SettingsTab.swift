//
//  SettingsTab.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general        = "General"
    case behavior       = "Behavior"
    case about          = "About"
    
    var color: Color {
        switch self {
        case .general:
            return Color.primary.opacity(0.15)
        case .behavior:
            return Color.primary.opacity(0.15)
        case .about:
            return Color.primary.opacity(0.15)
        }
    }
    
    var titleColor: Color {
        switch self {
        case .general:
            return Color.primary.opacity(0.75)
        case .behavior:
            return Color.primary.opacity(0.75)
        case .about:
            return Color.primary.opacity(0.75)
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .general:      GeneralSettings()
        case .behavior:     BehaviorSettings()
        case .about:        AboutView()
        }
    }
    
    /// Gives SystemName
    var icon: String {
        switch self {
        case .general:      return "gearshape"
        case .behavior:     return "line.horizontal.3"
        case .about:        return "info.circle"
        }
    }
}
