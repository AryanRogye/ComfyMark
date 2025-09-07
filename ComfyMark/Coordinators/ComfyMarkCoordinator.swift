//
//  ComfyMarkCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import AppKit

@MainActor
class ComfyMarkCoordinator {
    
    let windowCoordinator: WindowCoordinator
    
    var comfyMarkVMs: [String: ComfyMarkViewModel] = [:]

    init(windows: WindowCoordinator) {
        self.windowCoordinator = windows
    }
    
    var onLastRenderTimeUpdated: ((TimeInterval) -> Void)?
    
    func showComfyMark(
        with image : CGImage,
        export     : ExportProviding,
        saving     : SavingProviding,
        screenshotManager : ScreenshotManager,
        onLastRenderTimeUpdated: @escaping ((TimeInterval) -> Void),
        windowID: String
    ) {
        print("Got Window ID: \(windowID)")
        self.onLastRenderTimeUpdated = onLastRenderTimeUpdated
        
        let comfyMarkVM = ComfyMarkViewModel(
            image: image,
            windowID: windowID
        )
        comfyMarkVMs[windowID] = comfyMarkVM
        
        // MARK: - Export
        comfyMarkVM.onExport = { format, cgImage in
            return export.export(cgImage, format: format)
        }
        
        // MARK: - Cancel
        comfyMarkVM.onCancelTapped = { [weak self] in
            self?.windowCoordinator.closeWindow(id: windowID)
        }
        
        // MARK: - Save
        comfyMarkVM.onSaveTapped = { [weak self] image, projectName in
            guard let self = self else { return }
            let _ = try? saving.saveCGImage(
                image,
                name: projectName,
                type: .png
            )
            
            Task {
                await screenshotManager.loadHistoryInBackground()
            }
            
            self.renameKey(from: windowID, to: projectName)
        }
        // MARK: - Last Render Time
        comfyMarkVM.onLastRenderTimeUpdated = { [weak self] time in
            guard let self = self else { return }
            onLastRenderTimeUpdated(time)
        }
        
        let view = ComfyMarkView(
            comfyMarkVM: comfyMarkVM,
        )
        
        /// TODO: Let Settings allow the default screenshot size
        let padding = CGFloat(32)
        let screen = ScreenshotService.screenUnderMouse() ?? NSScreen.main!
        let size = NSSize(width: screen.frame.width - padding, height: screen.frame.height - padding)
        
        windowCoordinator.showWindow(
            id: windowID,
            title: "Image",
            content: view,
            size: size,
            onOpen: { [weak self] in
                self?.windowCoordinator.activateWithRetry()
            },
            onClose: { [weak self] in
                guard let self = self else { return }
                self.comfyMarkVMs.removeValue(forKey: windowID)
                NSApp.activate(ignoringOtherApps: false)
            })
    }
    
    func renameKey(from oldKey: String, to newKey: String) {
        guard let value = comfyMarkVMs.removeValue(forKey: oldKey) else { return }
        comfyMarkVMs[newKey] = value
        print("Renamed Key To: \(newKey)")
    }
}
