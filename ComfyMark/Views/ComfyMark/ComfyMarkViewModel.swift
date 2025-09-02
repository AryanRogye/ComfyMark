//
//  ComfyMarkViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import AppKit
import SwiftUI

@MainActor
class ComfyMarkViewModel: ObservableObject {
    
    let windowID : String
    @Published var image: CGImage
    @Published var strokes: [Stroke] = []
    
    @Published var exported : ExportedData?
    @Published var exportDocument: ExportDocument?
    @Published var exportSuggestedName: (String) -> String = { $0 }
    
    var internalIndex: Int = 0
    var hasActiveStroke: Bool {
        strokes.indices.contains(internalIndex)
    }
    
    
    init(image: CGImage, windowID: String) {
        self.image = image
        self.windowID = windowID
    }
    
    var onExport : ((ExportFormat) -> ExportedData?)?
    @Published var shouldExport = false
    
    var onCancelTapped: (() -> Void)?

    // MARK: - Closure Handling
    func onExport(_ format: ExportFormat) {
        guard let onExport = onExport else { return }
        exported = onExport(format)
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
        
    
    func onCancel() {
        guard let onCancelTapped = onCancelTapped else { return }
        onCancelTapped()
    }
    
    
    // MARK: - For Drawing
    func beginStroke(at point: CGPoint) {
        strokes.append(Stroke(points: [point]))
        internalIndex = strokes.count - 1
    }
    
    func addPoint(_ point: CGPoint) {
        guard strokes.indices.contains(internalIndex) else { return }
        strokes[internalIndex].points.append(point)
    }
    
    func endStroke() {
        internalIndex = strokes.count // next stroke index will be out-of-range until beginStroke is called again
    }
}
