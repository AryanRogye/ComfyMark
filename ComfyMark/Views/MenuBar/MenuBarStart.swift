//
//  MenuBarStart.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI

struct MenuBarStart: View {
    
    @ObservedObject var menuBarVM: MenuBarViewModel
    @State private var isHovering = false
    
    var body: some View {
        ComfyMarkButton {
            Label("Mark", systemImage: "camera.viewfinder")
                .labelStyle(.titleAndIcon)
                .imageScale(.medium)
                .foregroundStyle(.white)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            menuBarVM.startButtonTapped
                            ? Color.red : Color.blue
                        )
                        .opacity(isHovering ? 0.95 : 1.0)
                }
                .onHover { isHovering = $0 }
                .accessibilityLabel("Mark screen")
        } action: {
            menuBarVM.startTapped()
        }
        .help("Capture & mark the screen (Set Hotkey in Settings)")
    }
}
