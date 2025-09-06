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
    
    var comfyMarkVM : ComfyMarkViewModel?
    
    init(windows: WindowCoordinator) {
        self.windowCoordinator = windows
    }
    
    func showComfyMark(
        with image : CGImage,
        export     : ExportProviding
    ) {
        
        let windowID = "comfymark-\(UUID().uuidString)"
        
        comfyMarkVM = ComfyMarkViewModel(
            image: image,
            windowID: windowID
        )
        
        guard let comfyMarkVM else { return }
        
        comfyMarkVM.onExport = { format, cgImage in
            return export.export(cgImage, format: format)
        }
        
        comfyMarkVM.onCancelTapped = { [weak self] in
            self?.windowCoordinator.closeWindow(id: comfyMarkVM.windowID)
        }
        
        let view = ComfyMarkView(
            comfyMarkVM: comfyMarkVM,
        )
        
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
            onClose: {
                NSApp.activate(ignoringOtherApps: false)
            })
    }
}
