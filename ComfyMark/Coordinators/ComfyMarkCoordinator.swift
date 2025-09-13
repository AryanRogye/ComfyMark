//
//  ComfyMarkCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import AppKit

struct ComfyMarkSession {
    let id: UUID = UUID()
    var windowID: String
    var projectName: String?
    var comfyMarkVM: ComfyMarkViewModel
    var isSaved: Bool = false
}

@MainActor
class ComfyMarkCoordinator {
    
    let windowCoordinator: WindowCoordinator
    
    /// windowID -> session
    var comfyMarkSessions: [String : ComfyMarkSession] = [:]

    init(windows: WindowCoordinator) {
        self.windowCoordinator = windows
    }
    
    /// We Have a window ID, this gives us fast lookup
    func showComfyMark(
        with image              : CGImage,
        export                  : ExportProviding,
        saving                  : SavingProviding,
        screenshotManager       : ScreenshotManager,
        onLastRenderTimeUpdated : @escaping ((TimeInterval) -> Void),
        windowID                : String,
        projectName             : String? = nil,
        side                    : ImageStagerSide? = nil
    ) {
        /// Make sure no session with the windowID
        if self.hasSession(for: windowID, projectName) {
            return
        }
        
        /// Create Session
        let session = createSession(
            with: image,
            windowID: windowID,
            projectName: projectName,
            export: export,
            saving: saving,
            screenshotManager: screenshotManager,
            onLastRenderTimeUpdated: onLastRenderTimeUpdated
        )
        
        /// Add Session
        comfyMarkSessions[windowID] = session
        
        /// Setting the ViewModel to this
        let view = ComfyMarkView(
            comfyMarkVM: session.comfyMarkVM
        )
        
        var windowSize: NSSize
        let paddingAround = CGFloat(32)
        let screen = ScreenshotService.screenUnderMouse() ?? NSScreen.main!
        let visibleFrame = screen.visibleFrame

        windowSize = NSSize(
            width: visibleFrame.width - (paddingAround * 2),
            height: visibleFrame.height - (paddingAround * 2)
        )
        let windowOrigin = CGPoint(
            x: visibleFrame.origin.x + paddingAround,
            y: visibleFrame.origin.y + paddingAround
        )
        
        if let side = side {
            windowCoordinator.showWindowWithGenie(
                id: windowID,
                title: projectName ?? "Image",
                content: view,
                size: windowSize,
                origin: windowOrigin,
                side: side,
                onOpen: { [weak self] in
                    self?.windowCoordinator.activateWithRetry()
                },
                onClose: { [weak self] in
                    guard let self = self else { return }
                    self.removeSession(for: windowID)
                    NSApp.activate(ignoringOtherApps: false)
                })
        } else {
            windowCoordinator.showWindow(
                id: windowID,
                title: projectName ?? "Image",
                content: view,
                size: windowSize,
                origin: windowOrigin,
                onOpen: { [weak self] in
                    self?.windowCoordinator.activateWithRetry()
                },
                onClose: { [weak self] in
                    guard let self = self else { return }
                    self.removeSession(for: windowID)
                    NSApp.activate(ignoringOtherApps: false)
                })
        }
    }
    
    /// Function to create a session
    private func createSession(
        with image              : CGImage,
        windowID                : String,
        projectName             : String? = nil,
        export                  : ExportProviding,
        saving                  : SavingProviding,
        screenshotManager       : ScreenshotManager,
        onLastRenderTimeUpdated : @escaping ((TimeInterval) -> Void)
    ) -> ComfyMarkSession {
        
        /// Create View Model
        let comfyMarkVM = ComfyMarkViewModel(
            image: image,
            windowID: windowID,
            projectName: projectName
        )
        
        /// Set its On Export Values
        comfyMarkVM.onExport = { format, cgImage in
            return export.export(cgImage, format: format)
        }
    
        /// Set its On Cancel Values
        comfyMarkVM.onCancelTapped = { [weak self] in
            self?.windowCoordinator.closeWindow(id: windowID)
        }
        
        /// Set its on Save Tapped Values
        comfyMarkVM.onSaveTapped = { [weak self] image, projectName, windowID in
            guard let self = self else { return }
            let _ = try? saving.saveCGImage(
                image,
                name: projectName,
                type: .png
            )
            
            Task {
                await screenshotManager.loadHistoryInBackground()
                self.updateSessionAfterSave(windowID: windowID, projectName: projectName)
            }
        }
        
        /// What it will do on the last tapped
        comfyMarkVM.onLastRenderTimeUpdated = { time in
            onLastRenderTimeUpdated(time)
        }
        
        let session = ComfyMarkSession(
            windowID: windowID,
            projectName: projectName,
            comfyMarkVM: comfyMarkVM,
            isSaved: projectName != nil
        )
        
        return session
    }
}


/// MARK: - Helpers
extension ComfyMarkCoordinator {
    
    /// Update Session After User Saves
    private func updateSessionAfterSave(windowID: String, projectName: String) {
        
        /// Make sure session exists
        guard var session = comfyMarkSessions[windowID] else { return }
        
        session.projectName = projectName
        session.isSaved = true
        comfyMarkSessions[windowID] = session
    }
    
    /// Function will let us know if we have a session or not
    private func hasSession(for id: String,_ projectName: String?) -> Bool {
        // If we have a projectName, only check for that
        if let projectName = projectName {
            return comfyMarkSessions.values.contains {
                $0.projectName == projectName && $0.isSaved
            }
        }
        
        // Otherwise, check by windowID
        return comfyMarkSessions[id] != nil
    }
    
    /// Remove Session from Hashmap
    private func removeSession(for id: String) {
        comfyMarkSessions[id] = nil
    }
}
