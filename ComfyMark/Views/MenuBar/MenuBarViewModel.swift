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
    
    @Published var renderTimeMs : TimeInterval = 0
    
    @Published var startButtonTapped: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var isShowingHistory: Bool = false
    
    @Published var menuBarWidth: CGFloat = 280
    @Published var menuBarHeight: CGFloat = 230
    
    private var cancellables: Set<AnyCancellable> = []
    
    var screenshotManager: ScreenshotManager
    var appSettings      : AppSettings

    init(
        appSettings      : AppSettings,
        screenshotManager: ScreenshotManager
    ) {
        
        self.screenshotManager = screenshotManager
        self.appSettings       = appSettings
        
        $isShowingHistory
            .sink { [weak self] isShowing in
                guard let self = self else { return }
                self.menuBarHeight = isShowing
                ? 340
                : 230
                self.menuBarWidth = isShowing
                ? 280
                : 280
            }
            .store(in: &cancellables)
    }
    
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
