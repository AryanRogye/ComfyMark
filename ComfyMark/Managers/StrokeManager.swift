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

struct DrawStrokeOperation: Undoable {
    var type: HistoryType = .draw
    let drawData : Stroke
    
    func perform() {
        
    }
    
    func revert() {
        
    }
}

struct EraseStrokeOperation: Undoable {
    var type: HistoryType = .erase
    var eraseData : Stroke
    
    func perform() {
        
    }
    
    func revert() {
        
    }
}

/// Class made in ComfyMark ViewModel
@MainActor
final class StrokeManager: ObservableObject {
    
    /// Finished strokes only
    @Published private(set) var strokes: [Stroke] = []
    
    /// The in-progress stroke is separate to avoid copying the whole strokes array every .append(point)
    @Published var activeStroke: Stroke? = nil
    
    var hasActiveStroke: Bool { activeStroke != nil }
    
    // MARK: - Input
    
    func beginStroke(at p: CGPoint, brushSize: Float = 10, color: NSColor = .black) {
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
    
    func allStrokesInOrder() -> [Stroke] { strokes }

    
    // MARK: - Remove
    /// Removes a stroke by id. Returns the removed stroke if present.
    @discardableResult
    func remove(withID id: UUID) -> Stroke? {
        guard let idx = strokes.firstIndex(where: { $0.id == id }) else { return nil }
        return strokes.remove(at: idx)
    }
    
    func endStroke(finalizingWith s: Stroke) {
        var s = s
        let raw = s.points
        let smoothed = catmullRom(points: raw, alpha: 0.5, segmentStep: max(1, Int(s.brushSize/2)))
        
        if !smoothed.isEmpty {
            s.points = smoothed
        }
        strokes.append(s)
        activeStroke = nil
    }
    
    func endStroke() {
        guard var s = activeStroke else { return }
        
        let raw = s.points
        let smoothed = catmullRom(points: raw, alpha: 0.5, segmentStep: max(1, Int(s.brushSize/2)))
        
        if !smoothed.isEmpty {
            s.points = smoothed
        }
        strokes.append(s)
        activeStroke = nil
    }
    
    // MARK: - Smoothing
    
    /// Uniform Catmull–Rom spline (alpha=0.5 is centripetal; avoids loops).
    /// Returns a densified set of points suitable for stroke quads in Metal.
    func catmullRom(points: [CGPoint], alpha: CGFloat, segmentStep: Int) -> [CGPoint] {
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
            let t0: CGFloat = 0
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
    
    
    /*
     
     Used To Measure the CatMullRom For Better Smoothing
     
     Usage:
     
     let smoothed = catmullRom(points: raw, alpha: 0.5, segmentStep: max(1, Int(s.brushSize/2)))
     let rawScore = smoothnessScore(raw)
     let smoScore = smoothnessScore(smoothed)
     let improvement = (rawScore - smoScore) / max(rawScore, 1e-6) // 0..1
     
     print("Raw score: \(rawScore), Smoothed score: \(smoScore), Improvement: \(improvement)")

     */
    private func smoothnessScore(_ pts: [CGPoint]) -> CGFloat {
        guard pts.count >= 3 else { return 0 }
        var turn: CGFloat = 0, length: CGFloat = 0
        for i in 1..<pts.count {
            let a = pts[i-1], b = pts[i]
            let dx = b.x - a.x, dy = b.y - a.y
            let seg = max(hypot(dx, dy), 1e-6)
            length += seg
            if i >= 2 {
                let c = pts[i-2]
                let v1 = CGVector(dx: a.x - c.x, dy: a.y - c.y)
                let v2 = CGVector(dx: b.x - a.x, dy: b.y - a.y)
                let dot = max(min((v1.dx*v2.dx + v1.dy*v2.dy) /
                                  (hypot(v1.dx,v1.dy)*hypot(v2.dx,v2.dy) + 1e-6), 1), -1)
                let angle = acos(dot) // radians
                turn += angle
            }
        }
        return turn / max(length, 1e-6) // radians per point-length
    }
}
