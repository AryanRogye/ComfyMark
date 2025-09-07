//
//  MenuBarMaterialButton.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI

struct MenuBarMaterialButton<Content: View>: View {
    
    
    var action: () -> Void
    var content: Content
    
    @State var isHovering = false
    
    init(
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) {
        self.content = content()
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
        }) {
            content
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isHovering
                            ? AnyShapeStyle(.ultraThinMaterial.opacity(0.5))
                            : AnyShapeStyle(.ultraThinMaterial)
                        )
                }
        }
        .buttonStyle(.plain)
        .onHover {
            isHovering = $0
        }
    }
}
