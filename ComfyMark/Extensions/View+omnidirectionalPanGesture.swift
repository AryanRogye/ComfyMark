//
//  View+PanGesture.swift (Optimized)
//  ComfyNotch
//
//  © 2025 Aryan Rogye – MIT licence
//

import SwiftUI
import AppKit

extension View {
    /// Attach an omnidirectional pan gesture to any SwiftUI view.
    /// The closure receives dx, dy deltas and current phase.
    func omnidirectionalPanGesture(action: @escaping (_ dx: CGFloat, _ dy: CGFloat, _ phase: NSEvent.Phase) -> Void) -> some View {
        background(
            OmnidirectionalPanGestureRepresentable(action: action)
                .frame(maxWidth: 0, maxHeight: 0)
        )
    }
}

private struct OmnidirectionalPanGestureRepresentable: NSViewRepresentable {
    let action: (CGFloat, CGFloat, NSEvent.Phase) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitorIfNeeded(attachedTo: NSView())
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    final class Coordinator: NSObject {
        private let action: (CGFloat, CGFloat, NSEvent.Phase) -> Void
        private var eventMonitor: Any?
        
        init(action: @escaping (CGFloat, CGFloat, NSEvent.Phase) -> Void) {
            self.action = action
            super.init()
        }
        
        deinit {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        
        func installMonitorIfNeeded(attachedTo view: NSView) -> NSView {
            guard eventMonitor == nil else { return view }
            
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self, weak view] event in
                guard let self = self,
                      let v = view,
                      event.window == v.window else { return event }
                self.handleScroll(event)
                return event
            }
            return view
        }
        
        @inline(__always)
        private func handleScroll(_ event: NSEvent) {
            // Get both X and Y deltas
            let dx: CGFloat
            let dy: CGFloat
            
            if event.hasPreciseScrollingDeltas {
                // Trackpad - use precise deltas
                dx = event.scrollingDeltaX
                dy = event.scrollingDeltaY
            } else {
                // Mouse wheel - use regular deltas (scaled for sensitivity)
                let scaleFactor: CGFloat = 10.0
                dx = event.deltaX * scaleFactor
                dy = event.deltaY * scaleFactor
            }
            
            // Send both deltas to the action
            action(dx, dy, event.phase)
        }
    }
}
