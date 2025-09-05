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
            GeometryReader { geo in
                ZStack {
                    MetalImageView(
                        viewport: $viewport,
                        comfyMarkVM: comfyMarkVM
                    )
                    .id(comfyMarkVM.windowID)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    comfyGestures(viewSize: geo.size),
                    including: .all
                )
                .simultaneousGesture(zoomGesture())
            }
        }
        toolbar: {
            ComfyMarkToolbar(
                comfyMarkVM: comfyMarkVM,
            )
        }
    }
    
    @State private var lastDrag: CGPoint?

    private func comfyGestures(viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                switch comfyMarkVM.currentState {
                case .draw: handleDrawChanged(value, viewSize)
                case .move: handleMoveChanged(value, viewSize)
                default: break
                }
            }
            .onEnded { _ in
                switch comfyMarkVM.currentState {
                case .draw: handleDrawEnded()
                case .move: handleMoveEnded()
                default: break
                }
            }
    }

    // MARK: - Move
    private func handleMoveChanged(_ value: DragGesture.Value, _ viewSize: CGSize) {
        /// If Dragging is the same
        if let last = lastDrag {
            let dx = value.location.x - last.x
            let dy = value.location.y - last.y
            /// Just Move a bit
            comfyMarkVM.panBy(dx: dx, dy: dy, viewSize: viewSize, viewport: &viewport)
        }
        /// Set It
        lastDrag = value.location
    }
    private func handleMoveEnded() {
        comfyMarkVM.endPan()
        lastDrag = nil
    }
    
    // MARK: - Draw
    private func handleDrawChanged(_ value: DragGesture.Value, _ viewSize: CGSize) {
        guard !isPinching else {
            return
        }
        if !comfyMarkVM.hasActiveStroke {
            /// If No Active Stroke, Start A New Stroke
            comfyMarkVM.beginStroke(at: value.location, viewSize: viewSize, viewport: viewport)
        } else {
            /// If Stroke Active, we just add a Point
            comfyMarkVM.addPoint(value.location, viewSize: viewSize, viewport: viewport)
        }
    }
    
    private func handleDrawEnded() {
        /// We End Stroke Here, this also triggers a new Stroke
//        comfyMarkVM.endStroke()
    }
    
    // MARK: - Zoom
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
}
