//
//  MenuBarViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import SwiftUI

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var startButtonTapped: Bool = false
    @Published var errorMessage: String? = nil
    
    var hasError: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { if !$0 { self.errorMessage = nil } }
        )
    }

    var onSettingsTapped: (() -> Void)?
    var onStartTapped: (() throws -> Void)?
    
    
    // MARK: - Start Tapped
    /// function will take trigger what it was set with
    public func startTapped() {
        if startButtonTapped { return }
        startButtonTapped = true
        defer { startButtonTapped = false }
        
        guard let onStartTapped = onStartTapped else { return }
        do {
            try onStartTapped()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Open Settings
    public func openSettings() {
        guard let onSettingsTapped = onSettingsTapped else { return }
        onSettingsTapped()
    }
}
