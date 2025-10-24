//
//  Stroke.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import SwiftUI

struct Stroke {
    var mode : StrokeKind
    var points: [CGPoint]
    var brushSize: Float
    var color: NSColor
    var timestamp: Date
    // cache of smoothed points (computed on end)
    var smoothed: [CGPoint]? = nil
}

enum StrokeKind {
    case draw
    case erase
}
