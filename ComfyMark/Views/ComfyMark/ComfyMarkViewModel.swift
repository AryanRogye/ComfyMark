//
//  ComfyMarkViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import AppKit
import SwiftUI


struct Stroke {
    var points : [CGPoint]
    var color  : Color = .red
    var width  : CGFloat = 10
}

@MainActor
class ComfyMarkViewModel: ObservableObject {
    
    @Published var image: CGImage
    @Published var strokes: [Stroke] = []
    
    var internalIndex: Int = 0
    var hasActiveStroke: Bool {
        strokes.indices.contains(internalIndex)
    }
    
    init(image: CGImage) {
        self.image = image
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
