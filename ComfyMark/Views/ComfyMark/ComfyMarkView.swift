//
//  ComfyMarkView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI


struct ComfyMarkDrawingView: View {
    
    @ObservedObject var comfyMarkVM : ComfyMarkViewModel
    @Binding var viewport: Viewport
    
    var body: some View {
        Canvas { ctx, _ in
            
//            ctx.translateBy(x: -CGFloat(viewport.origin.x), y: -CGFloat(viewport.origin.y))
//            ctx.scaleBy(x: CGFloat(viewport.scale), y: CGFloat(viewport.scale))
            
            for s in comfyMarkVM.strokes {
                guard s.points.count > 1 else { continue }
                var p = Path()
                p.addLines(s.points)
                ctx.stroke(p, with: .color(s.color), lineWidth: s.width)
            }
            
            // debug: last point dot
            if let p = comfyMarkVM.strokes.last?.points.last {
                let r = CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)
                ctx.fill(Path(ellipseIn: r), with: .color(.blue))
            }
        }
        .allowsHitTesting(false)
    }
}
struct ComfyMarkView: View {
    
    @ObservedObject var comfyMarkVM : ComfyMarkViewModel
    @State private var viewport = Viewport()
    @State private var pinchStartScale: Float? = nil
    @State var isPinching = false
    
    var body: some View {
        CustomToolbarView {
            ZStack {
                MetalImageView(
                    image: $comfyMarkVM.image,
                    viewport: $viewport
                )
                .overlay {
                    ComfyMarkDrawingView(
                        comfyMarkVM: comfyMarkVM,
                        viewport: $viewport
                    )
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(dragGesture(), including: .all)
            .simultaneousGesture(zoomGesture())
        }
        toolbar: {
            ComfyMarkToolbar(comfyMarkVM: comfyMarkVM)
        }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture(minimumScaleDelta: 0)
            .onChanged { value in
                isPinching = true
                if pinchStartScale == nil { pinchStartScale = viewport.scale }
                let base = pinchStartScale ?? viewport.scale
                viewport.scale = max(0.1, min(8.0, base * Float(value)))
            }
            .onEnded { _ in
                isPinching = false
                pinchStartScale = nil
            }
    }
    
    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard !isPinching else {
                    return
                }
                if !comfyMarkVM.hasActiveStroke {
                    /// If No Active Stroke, Start A New Stroke
                    comfyMarkVM.beginStroke(at: v.location)
                } else {
                    /// If Stroke Active, we just add a Point
                    comfyMarkVM.addPoint(v.location)
                }
            }
            .onEnded { _ in
                /// We End Stroke Here, this also triggers a new Stroke
                comfyMarkVM.endStroke()
            }
    }
}
