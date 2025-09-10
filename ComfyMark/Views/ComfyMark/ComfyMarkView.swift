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
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                comfyMarkDownView()
                
                if comfyMarkVM.showHistory {
                    HistoryView(
                        comfyMarkVM: comfyMarkVM,
                        geo: geo
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func comfyMarkDownView() -> some View {
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
                .omnidirectionalPanGesture { dx, dy, phase in
                    handleTrackpadPan(dx: dx, dy: dy, phase: phase, viewSize: geo.size)
                }
            }
        }
        toolbar: {
            ComfyMarkToolbar(
                comfyMarkVM: comfyMarkVM,
            )
        }
        .alert(
            (comfyMarkVM.alertTitle?.isEmpty == false ? comfyMarkVM.alertTitle! : "Error"),
            isPresented: $comfyMarkVM.shouldShowAlert,
            presenting: comfyMarkVM.alertMessage ?? "Something went wrong."
        ) { _ in
            Button("OK", role: .cancel) { comfyMarkVM.shouldShowAlert = false }
        } message: { msg in
            Text(msg)
        }
    }
    
    // MARK: - Trackpad Pan (two-finger gesture)
    @State private var lastTrackpadDelta: (x: CGFloat, y: CGFloat) = (0, 0)

    /// Trackpad is setup so that you can use it while drawing
    private func handleTrackpadPan(dx: CGFloat, dy: CGFloat, phase: NSEvent.Phase, viewSize: CGSize) {
        switch phase {
        case .began:
            // Pan started - could do initialization here if needed
            break
            
        case .changed:
            // Use the deltas directly - they're already incremental
            comfyMarkVM.panBy(dx: dx, dy: dy, viewSize: viewSize, viewport: &viewport)
            
        case .ended, .cancelled:
            // Pan ended
            comfyMarkVM.endPan()
            
        default:
            break
        }
    }
    
    // MARK: - Comfy Gestures
    @State private var lastDrag  : CGPoint?
    @State private var lastErase : CGPoint?

    private func comfyGestures(viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                switch comfyMarkVM.currentState {
                case .draw: handleDrawChanged(value, viewSize)
                case .erase: handleEraseChanged(value, viewSize)
                case .move: handleMoveChanged(value, viewSize)
                default: break
                }
            }
            .onEnded { _ in
                switch comfyMarkVM.currentState {
                case .draw: handleDrawEnded()
                case .erase: handleEraseEnded()
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
        if !comfyMarkVM.strokeManager.hasActiveStroke {
            /// If No Active Stroke, Start A New Stroke
            comfyMarkVM.beginStroke(at: value.location, viewSize: viewSize, viewport: viewport)
        } else {
            /// If Stroke Active, we just add a Point
            comfyMarkVM.addPoint(value.location, viewSize: viewSize, viewport: viewport)
        }
    }
    
    private func handleDrawEnded() {
        comfyMarkVM.endStroke()
    }
    
    // MARK: - Erase
    private func handleEraseChanged(_ value: DragGesture.Value, _ viewSize: CGSize) {
        guard !isPinching else {
            return
        }
        
        if !comfyMarkVM.strokeManager.hasActiveStroke {
            /// If No Active Stroke, Start A New Stroke
            comfyMarkVM.beginErase(at: value.location, viewSize: viewSize, viewport: viewport)
        } else {
            /// If Stroke Active, we just add a Point
            comfyMarkVM.addErasePoint(at: value.location, viewSize: viewSize, viewport: viewport)
        }
    }
    
    private func handleEraseEnded() {
        comfyMarkVM.endStroke()
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
