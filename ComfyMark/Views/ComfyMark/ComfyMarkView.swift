//
//  ComfyMarkView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

struct ComfyMarkView: View {
    
    @ObservedObject var comfyMarkVM : ComfyMarkViewModel
    
    var body: some View {
        CustomToolbarView {
            ZStack {
                MetalImageView(image: $comfyMarkVM.image)
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
