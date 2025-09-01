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
        ZStack {
            Image(decorative: comfyMarkVM.image, scale: 1, orientation: .up)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Canvas { ctx, _ in
                for s in comfyMarkVM.strokes {
                    guard s.points.count > 1 else { continue }
                    var p = Path()
                    p.addLines(s.points)
                    ctx.stroke(p, with: .color(s.color), lineWidth: s.width)
                }
            }
        }
        .contentShape(Rectangle()) // ensure gesture hits transparent areas
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    if !comfyMarkVM.hasActiveStroke {
                        comfyMarkVM.beginStroke(at: v.location)
                    } else {
                        comfyMarkVM.addPoint(v.location)
                    }
                }
                .onEnded { _ in comfyMarkVM.endStroke() }
        )
    }
}
