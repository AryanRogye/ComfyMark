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
        
        comfyMarkVM.onExport = { format in
            return export.export(image, format: format)
        }
        
        comfyMarkVM.onCancelTapped = { [weak self] in
            self?.windowCoordinator.closeWindow(id: comfyMarkVM.windowID)
        }
        
        let view = ComfyMarkView(
            comfyMarkVM: comfyMarkVM
        )
        
        windowCoordinator.showWindow(
            id: windowID,
            title: "Image",
            content: view,
            size: NSSize(width: 800, height: 500),
            onOpen: { [weak self] in
                self?.windowCoordinator.activateWithRetry()
            },
            onClose: {
                NSApp.activate(ignoringOtherApps: false)
            })
    }
}
