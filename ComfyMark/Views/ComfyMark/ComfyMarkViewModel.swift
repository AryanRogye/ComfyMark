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
    
    var internalIndex: Int = 0
    var hasActiveStroke: Bool {
        strokes.indices.contains(internalIndex)
    }
    
    init(image: CGImage, windowID: String) {
        self.image = image
        self.windowID = windowID
    }
    
    var onCancelTapped: (() -> Void)?
    
    func onCancel() {
        guard let onCancelTapped = onCancelTapped else { return }
        onCancelTapped()
    }
    
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
