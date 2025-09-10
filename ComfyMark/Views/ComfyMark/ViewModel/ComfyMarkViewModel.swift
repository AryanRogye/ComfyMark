//
//  ComfyMarkViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import AppKit
import SwiftUI
import Metal
import MetalKit

@MainActor
class ComfyMarkViewModel: ObservableObject {
    
    /// Objects
    let ctx = MetalContext.shared
    var metalBrush : MetalBrush?
    var strokeManager : StrokeManager
    var historyManager = HistoryManager()
    
    /// Passed in
    let windowID : String
    @Published var image: CGImage
    @Published var projectName: String

    /// Textures
    @Published var imageTexture: MTLTexture?
    @Published var inkTexture : MTLTexture?
    
    /// Alert Related
    @Published var alertTitle: String? = nil
    @Published var alertMessage: String? = nil
    @Published var shouldShowAlert: Bool = false

    /// Brush Related
    @Published var brushRadius: Float = 10
    @Published var shouldShowBrushRadiusPopover: Bool = false
    
    /// Export Related
    @Published var exported : ExportedData?
    @Published var exportDocument: ExportDocument?
    @Published var exportSuggestedName: (String) -> String = { $0 }
    @Published var shouldExport = false
    
    /// Current State For Toolbar
    @Published var currentState : EditorState = .move
    /// Update State for ink
    @Published var shouldUpdate : Bool = false
    
    @Published var showHistory  : Bool = false


    // MARK: - Closures
    /// This will be used/called to get the image from metal
    /// this will be used directly inside the metalView - `MetalImageView.swift`
    var getMetalImage: (() -> CGImage?)?
    
    /// Cacel The View - Set by Coordinator
    var onCancelTapped: (() -> Void)?
    
    /// Save whatever we did - Set by Coordinator
    var onSaveTapped: ((CGImage, String, String) -> Void)?
        
    /// Handling Sending Back Last Render Time
    var onLastRenderTimeUpdated: ((TimeInterval) -> Void)?
    
    /// Handling Exporting
    var onExport : ((ExportFormat, CGImage) -> ExportedData?)?

    init(image: CGImage, windowID: String, projectName: String?) {
        
        self.image = image
        self.windowID = windowID
        self.projectName = projectName ?? ""
        
        strokeManager = StrokeManager()
        
        
        imageTexture = try? self.getImageTexture(from: image)
        if let imageTexture = imageTexture {
            inkTexture = try? getInkTexture(baseTexture: imageTexture)
        }
        
        if let inkTexture = inkTexture {
            metalBrush = MetalBrush(inkTexture: inkTexture)
            metalBrush?.onStampDone = { [weak self] in
                self?.shouldUpdate = true
            }
        }
    }
}

// MARK: - 📚 History
extension ComfyMarkViewModel {
    public func toggleHistoryView() {
        showHistory.toggle()
    }
}

// MARK: - Undo/Redo, TODO
extension ComfyMarkViewModel {
    
    public func undo() {
        historyManager.undo()
    }
    public func redo() {
        historyManager.redo()
    }
    
}

// MARK: - 🚨 Alerts
extension ComfyMarkViewModel {
    func showAlert(title: String, message: String) {
        alertTitle = title.isEmpty ? "Error" : title
        alertMessage = message
        shouldShowAlert = true
    }
}

// MARK: - 🧭 Radius {
extension ComfyMarkViewModel {
    public func shouldShowRadius() {
        shouldShowBrushRadiusPopover = true
    }
}

// MARK: 🖍️ Drawing
extension ComfyMarkViewModel {
    func beginStroke(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        /// wherever we touch, we convert that into what px we touched on the image
        let clampedPt = clampToImageBounds(viewToImagePx(point, viewSize: viewSize, viewport: viewport))
        strokeManager.beginStroke(at: clampedPt)
    }
    
    /*
     Function Will Draw A Point From First Point To The NExt One:
     // Touch 1: (100, 200) → no previous point, so no line drawn yet
     // Touch 2: (105, 205) → draws line from (100,200) to (105,205)
     // Touch 3: (110, 210) → draws line from (105,205) to (110,210)
     // Touch 4: (115, 215) → draws line from (110,210) to (115,215)
     */
    func addPoint(_ viewPoint: CGPoint, viewSize: CGSize, viewport: Viewport) {
        /// wherever we touch, we convert that into what px we touched on the image
        let imgPt = clampToImageBounds(viewToImagePx(viewPoint, viewSize: viewSize, viewport: viewport))
        
        // stash previous point (if any)
        let prev = strokeManager.activeStroke?.points.last
        
        // update model
        strokeManager.addPoint(imgPt)
        
        if let prev = prev {
            renderSegment(from: prev, to: imgPt)
        }
    }
    
    func endStroke() {
        strokeManager.endStroke()
    }
}

// MARK: 🧽 Erase
extension ComfyMarkViewModel {
    
    func beginErase(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let newP = viewToImagePx(point, viewSize: viewSize, viewport: viewport)
        let clampedPt = clampToImageBounds(newP)
        strokeManager.beginStroke(at: clampedPt)
    }
    func addErasePoint(at point: CGPoint, viewSize: CGSize, viewport: Viewport) {
        let imgPt = clampToImageBounds(viewToImagePx(point, viewSize: viewSize, viewport: viewport))
        
        // 1) stash previous point (if any)
        let prev = strokeManager.activeStroke?.points.last
        
        // 2) update model
        strokeManager.addPoint(imgPt)
        
        // 3) render only the delta (prev -> imgPt)
        if let p0 = prev {
            renderErase(from: p0, to: imgPt)
        }
    }
}

// MARK: - 🚶🏽 Moving/Panning
extension ComfyMarkViewModel {
    func panBy(dx: CGFloat, dy: CGFloat, viewSize: CGSize, viewport: inout Viewport) {
        let dx_c =  2 * Float(dx) / Float(viewSize.width)
        let dy_c = -2 * Float(dy) / Float(viewSize.height)
        
        viewport.origin.x -= dx_c / viewport.scale
        viewport.origin.y -= dy_c / viewport.scale
    }
    
    func endPan() {
        // reset anything if needed (like store new base)
    }
}
