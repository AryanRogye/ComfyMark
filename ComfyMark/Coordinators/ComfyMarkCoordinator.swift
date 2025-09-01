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
        with image : CGImage
    ) {
        comfyMarkVM = ComfyMarkViewModel(image: image)
        guard let comfyMarkVM else { return }
        
        let view = ComfyMarkView(
            comfyMarkVM: comfyMarkVM
        )
        
        windowCoordinator.showWindow(
            id: "comfymark-\(UUID().uuidString)",
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
