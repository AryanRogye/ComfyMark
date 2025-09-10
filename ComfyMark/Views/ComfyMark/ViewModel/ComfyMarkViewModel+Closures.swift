//
//  ComfyMarkViewModel+Closures.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import SwiftUI

// MARK: - ViewModel + Closures
/*
 // onLastRenderTime : Function Calls onLastRenderTimeUpdated, set by
 //                    ComfyMarkCoordinator, Called by `MetalImageView.swift`
 --------------------------------------------------------------------------------
 // onExport         : Function handles what we do on Exporting,
 //    Closure Params:
 //                    - onExport is set by the coordinator that passes this into the view
 //                    - getMetalImage is setup by our metalView - `MetalImageView.swift`
 --------------------------------------------------------------------------------
 // onCancel         : Function handles what happens if we press cancel
 //                    Closure is set by ComfyMarkCoordinator
 --------------------------------------------------------------------------------
 // onSave           : Function handles what happens if we press save
 --------------------------------------------------------------------------------
 */
extension ComfyMarkViewModel {
    
    public func onLastRenderTime(_ time: TimeInterval) {
        guard let onLastRenderTimeUpdated = onLastRenderTimeUpdated else {
            print("Returned On Last Render Time Cuz No Closure Was Set")
            return
        }
        onLastRenderTimeUpdated(time)
    }
    
    public func onExport(_ format: ExportFormat) {
        
        /// Verify We Have a onExport
        guard let onExport = onExport else { return }
        
        /// Verify we can call the metal to get the image
        guard let getMetalImage = getMetalImage else {
            print("Returned On Export Cuz No Metal Image Function Was Set")
            return
        }
        
        let cgimage = getMetalImage()
        guard let cgimage = cgimage else {
            return
        }
        
        exported = onExport(format, cgimage)
        
        // get raw bytes (handles both .data and .nsImage if you kept that case)
        let bytes: Data
        switch exported {
        case .data(let d):
            bytes = d
        default:
            return
        }
        
        exportDocument = ExportDocument(data: bytes, contentType: format.utType)
        exportSuggestedName = format.defaultFilename
        shouldExport = true // triggers .fileExporter
    }
    
    
    public func onCancel() {
        guard let onCancelTapped = onCancelTapped else { return }
        onCancelTapped()
    }
    
    public func onSave() {
        guard let onSaveTapped = onSaveTapped else { return }
        
        /// Make sure project name is not empty
        guard !projectName.isEmpty else {
            showAlert(title: "Project Name Required", message: "Please enter a project name")
            return
        }
        
        /// Verify we can call the metal to get the image
        guard let getMetalImage = getMetalImage else {
            print("Returned On Export Cuz No Metal Image Function Was Set")
            return
        }
        
        let cgimage = getMetalImage()
        guard let cgimage = cgimage else {
            return
        }
        
        
        onSaveTapped(cgimage, projectName, windowID)
    }
}
