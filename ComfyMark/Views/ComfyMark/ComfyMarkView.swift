//
//  ComfyMarkView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

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
                Canvas { ctx, _ in
                    for s in comfyMarkVM.strokes {
                        guard s.points.count > 1 else { continue }
                        var p = Path()
                        p.addLines(s.points)
                        ctx.stroke(p, with: .color(s.color), lineWidth: s.width)
                    }
                }
            }
        }
        toolbar: {
            ComfyMarkToolbar(comfyMarkVM: comfyMarkVM)
        }
        .contentShape(Rectangle()) // ensure gesture hits transparent areas
        .gesture(dragGesture())
        .gesture(zoomGesture())
    }
    
//    private func zoomGesture2() -> some Gesture {
//        MagnificationGesture(minimumScaleDelta: 0)
//    }
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
