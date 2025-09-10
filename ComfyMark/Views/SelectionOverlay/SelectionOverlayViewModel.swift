//
//  SelectionOverlayViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

import Combine
import SwiftUI

final class SelectionOverlayViewModel: ObservableObject {
    // MARK: - Outputs
    @Published var dragStart: CGPoint?
    @Published var dragCurrent: CGPoint?

    // Optional callback with final rect (in view coordinates)
    var onSelectionFinished: ((CGRect) -> Void)?
    var onExit: (() -> Void)?
}

// MARK: - Public API
extension SelectionOverlayViewModel {
    // Begin drag at point (always start a new selection)
    func beginDrag(at point: CGPoint) {
        dragStart = point
        dragCurrent = point
    }

    // Update drag location
    func updateDrag(to point: CGPoint) {
        dragCurrent = point
    }

    // End drag, emit final rect and keep it visible (consumer may clear)
    func endDrag(at point: CGPoint) {
        dragCurrent = point
        
        if let rect = selectionRect {
            onSelectionFinished?(rect)
        }
    }

    // Clear current selection
    func clearSelection() {
        dragStart = nil
        dragCurrent = nil
    }

    public func exit() {
        onExit?()
    }
}

// MARK: - Derived values
extension SelectionOverlayViewModel {
    // Normalized rect from start/current in local view coordinates
    var selectionRect: CGRect? {
        guard let s = dragStart, let c = dragCurrent else { return nil }
        let x = min(s.x, c.x)
        let y = min(s.y, c.y)
        let w = abs(c.x - s.x)
        let h = abs(c.y - s.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    var selectionSizeText: String? {
        guard let rect = selectionRect, rect.width > 0, rect.height > 0 else { return nil }
        return "\(Int(rect.width)) × \(Int(rect.height))"
    }
}
