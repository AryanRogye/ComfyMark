//
//  ViewSidebar.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import SwiftUI

struct ViewSidebar<Content: View>: View {
    var content: Content
    var geo: GeometryProxy
    
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    
    // Optional: Add constraints for how far the sidebar can be dragged
    private let minOffset: CGFloat = -200 // Can drag left up to 200 points
    private let maxOffset: CGFloat = 200  // Can drag right up to 200 points
    private let baseWidth: CGFloat = 200

    
    init(
        _ geo: GeometryProxy,
        @ViewBuilder content: () -> Content
    ) {
        self.geo = geo
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .sidebar)
            
            self.content
                
            HStack {
                Spacer()
                dragHandle
            }
        }
        .frame(maxWidth: max(baseWidth + dragOffset, 80), maxHeight: .infinity)
        .position(x: (max(baseWidth + dragOffset, 80)) / 2, y: geo.size.height / 2)
        .gesture(dragGesture())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
    }
    
    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Calculate the new offset based on drag translation
                let newOffset = lastDragValue + value.translation.width
                
                // Apply constraints
                dragOffset = max(minOffset, min(maxOffset, newOffset))
            }
            .onEnded { value in
                // Store the final position for the next drag
                lastDragValue = dragOffset
                
                // Optional: Add snap-to behavior
                snapToNearestPosition()
            }
    }
    
    @ViewBuilder
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.secondary.opacity(0.5))
            .frame(maxWidth: 4, maxHeight: .infinity)
            .padding(.horizontal, 1)
    }
    
    private func snapToNearestPosition() {
        // Optional: Snap to specific positions
        let snapPoints: [CGFloat] = [-100, 0, 100] // Define snap points
        
        let closestSnap = snapPoints.min { abs($0 - dragOffset) < abs($1 - dragOffset) }
        
        if let snap = closestSnap, abs(snap - dragOffset) < 30 {
            dragOffset = snap
            lastDragValue = snap
        }
    }
}
