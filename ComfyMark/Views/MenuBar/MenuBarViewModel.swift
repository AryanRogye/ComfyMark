//
//  MenuBarViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import SwiftUI
import ImageIO


@MainActor
class MenuBarViewModel: ObservableObject {
    
    /// Used For Selecting In History
    @Published var selectedHistoryIndex: Int? = nil
    @Published var selectedHistoryIndexs: Set<Int> = []
    
    /// This will Return to us a nicely made list of [ScreenshotThumbnailInfo] used to parse
    var selectedItems: [ScreenshotThumbnailInfo] {
        let sorted = screenshotManager.screenshotHistory
            .sorted { fileDate($0.url) > fileDate($1.url) }
        let indices = selectedHistoryIndexs
        return indices.compactMap { idx in
            guard idx >= 0 && idx < sorted.count else { return nil }
            return sorted[idx]
        }
    }
    
    var selectedItemsIsEmtpy: Bool {
        return selectedItems.isEmpty
    }
    
    
    @Published var showMoreOptions: Bool = false
    @Published var historyErasePressed: Bool = false
    
    @Published var renderTimeMs : TimeInterval = 0
    
    @Published var startButtonTapped: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var isShowingHistory: Bool = false
    @Published var isShowingMultipleDelete : Bool = false
    
    @Published var menuBarWidth: CGFloat = 280
    @Published var menuBarHeight: CGFloat = 225
    
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
                ? 400
                : 226
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
    var onStartTappedImage: ((CGImage, String) -> Void)?
    
    var onStartTapped: (() throws -> Void)?
    var onCrop: (() -> Void)?
    
    
    public func onStartTappedOn(_ history: ScreenshotThumbnailInfo) {
        guard let onStartTappedImage = onStartTappedImage else { return }
        
        let url = history.url
        
        if ScreenshotManager.isImageFile(url) {
            guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
            if let cgImage: CGImage = CGImageSourceCreateImageAtIndex(src, 0, nil) {
                let fileName = url.deletingPathExtension().lastPathComponent
                onStartTappedImage(cgImage, fileName)
            }
        }
    }
    
    public func startCropped() {
        
        if startButtonTapped { return }
        startButtonTapped = true
        defer { startButtonTapped = false }
        
        guard let onCrop = onCrop else { return }
        onCrop()
    }
    
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
    
    
    // MARK: - Handle Multiple Deleted Shortcut
    public func handleMultipleDeleteShortcut() {
        /// This means we did command delete on multiple things
        if selectedHistoryIndexs.count > 1 {
            //            print("Multiple Deleted Shortcut")
            //            print("Deleting Now")
            isShowingMultipleDelete = true
        }
        /// This means we did command delete, AND we have something selected
        /// so that means we prolly meant to delete it
        else if selectedHistoryIndex != nil {
            showMoreOptions = true
            historyErasePressed = true
        }
    }
    
    @Published var isDeleting: Bool = false

    // MARK: - Remove URL
    func removeURL(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to delete file: \(error)")
        }
    }
    
    // MARK: - Mass Remove
    func performMassDelete() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }
        
        let fm = FileManager.default
        for item in selectedItems {
            do {
                var resultingURL: NSURL? = nil
                try fm.trashItem(at: item.url, resultingItemURL: &resultingURL)
            } catch {
                do { try fm.removeItem(at: item.url) } catch { /* ignore */ }
            }
        }
        
        await screenshotManager.loadHistoryInBackground()
        selectedHistoryIndexs.removeAll()
        selectedHistoryIndex = nil
        isShowingMultipleDelete = false
    }
    
    // MARK: - Helpers
    private func fileDate(_ url: URL) -> Date {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate]) as? Date ?? .distantPast
    }
}
