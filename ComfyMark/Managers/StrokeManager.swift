//
//  StrokeManager.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/5/25.
//

import Foundation
import CoreGraphics
import Combine
import SwiftUI

@MainActor
final class StrokeManager: ObservableObject {
    
    // Finished strokes only (stable; good for @Published)
    @Published private(set) var strokes: [Stroke] = []
    
    // The in-progress stroke is separate to avoid copying the whole strokes array every .append(point)
    @Published var activeStroke: Stroke? = nil
    
    // Redo stack (push here when you undo)
    private var redoStack: [Stroke] = []
    
    var hasActiveStroke: Bool { activeStroke != nil }
    var canUndo: Bool { !strokes.isEmpty || activeStroke != nil }
    var canRedo: Bool { !redoStack.isEmpty }
    
    // MARK: - Input
    
    func beginStroke(at p: CGPoint, brushSize: Float = 10, color: NSColor = .black) {
        // New stroke invalidates redo history
        redoStack.removeAll()
        activeStroke = Stroke(points: [p], brushSize: brushSize, color: color, timestamp: .now)
    }
    
    func addPoint(_ p: CGPoint) {
        guard var s = activeStroke else { return }
        // Optional: downsample to avoid tiny jitter & huge point arrays
        if let last = s.points.last {
            let dx = p.x - last.x, dy = p.y - last.y
            let dist2 = dx*dx + dy*dy
            if dist2 < 1.5 * 1.5 { return } // ignore < ~1.5px moves; tune
        }
        s.points.append(p)
        activeStroke = s // publish minimal object, not whole strokes array
    }
    
    func endStroke() {
        guard var s = activeStroke else { return }
        s.smoothed = catmullRom(points: s.points, alpha: 0.5, segmentStep: max(1, Int(s.brushSize / 2)))
        strokes.append(s)
        activeStroke = nil
    }
    
    // MARK: - Undo / Redo
    
    @discardableResult
    func undo() -> Stroke? {
        // If user is mid-stroke, cancel that first
        if let s = activeStroke {
            activeStroke = nil
            redoStack.append(s)
            return s
        }
        guard let last = strokes.popLast() else { return nil }
        redoStack.append(last)
        return last
    }
    
    @discardableResult
    func redo() -> Stroke? {
        guard var s = redoStack.popLast() else { return nil }
        // If it was an in-progress undo, restore as finished
        if s.smoothed == nil { s.smoothed = catmullRom(points: s.points, alpha: 0.5, segmentStep: max(1, Int(s.brushSize / 2))) }
        strokes.append(s)
        return s
    }
    
    // MARK: - Rendering helpers
    
    /// Call this for final draw: use smoothed if available, else raw.
    func strokesForRender() -> [Stroke] {
        strokes
    }
    
    /// Optional: a live feed for previewing the active stroke during drawing
    func activePointsForRender() -> [CGPoint] {
        activeStroke?.points ?? []
    }
    
    // MARK: - Smoothing
    
    /// Uniform Catmull–Rom spline (alpha=0.5 is centripetal; avoids loops).
    /// Returns a densified set of points suitable for stroke quads in Metal.
    private func catmullRom(points: [CGPoint], alpha: CGFloat, segmentStep: Int) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var out: [CGPoint] = []
        let pts = [points.first!] + points + [points.last!]
        
        func tj(_ pi: CGPoint, _ pj: CGPoint, _ ti: CGFloat) -> CGFloat {
            let dx = pj.x - pi.x, dy = pj.y - pi.y
            let d = sqrt(dx*dx + dy*dy)
            return ti + pow(d, alpha)
        }
        
        for i in 0..<(pts.count - 3) {
            let p0 = pts[i], p1 = pts[i+1], p2 = pts[i+2], p3 = pts[i+3]
            var t0: CGFloat = 0
            let t1 = tj(p0, p1, t0)
            let t2 = tj(p1, p2, t1)
            let t3 = tj(p2, p3, t2)
            
            for step in 0...segmentStep {
                let t = t1 + (t2 - t1) * (CGFloat(step) / CGFloat(segmentStep))
                let A1 = lerp(p0, p1, (t - t0)/(t1 - t0))
                let A2 = lerp(p1, p2, (t - t1)/(t2 - t1))
                let A3 = lerp(p2, p3, (t - t2)/(t3 - t2))
                let B1 = lerp(A1, A2, (t - t1)/(t2 - t1))
                let B2 = lerp(A2, A3, (t - t2)/(t3 - t2))
                let C  = lerp(B1, B2, (t - t2)/(t2 - t1))
                out.append(C)
            }
        }
        return out
    }
    
    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
