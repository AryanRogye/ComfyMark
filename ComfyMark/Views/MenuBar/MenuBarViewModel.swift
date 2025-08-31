//
//  MenuBarViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import SwiftUI

class MenuBarViewModel: ObservableObject {
    @Published var startButtonTapped: Bool = false
    
    var onSettingsTapped: (() -> Void)?
    var onStartTapped: (() -> Void)?
    
    public func openSettings() {
        guard let onSettingsTapped = onSettingsTapped else { return }
        onSettingsTapped()
    }
}
