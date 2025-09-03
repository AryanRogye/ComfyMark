//
//  ComfyMarkDrawingView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
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
