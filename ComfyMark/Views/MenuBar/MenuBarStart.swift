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
    
    @State private var startLogo: String = "camera.viewfinder"
    @State private var captureTick: Int = 0
    
    var body: some View {
        ComfyMarkButton {
            
            HStack(spacing: 4) {
                StartMarkLogo(isHovering: isHovering, symbolName: startLogo, captureTick: captureTick)
                Text("Mark")
            }
            .labelStyle(.titleAndIcon)
            .imageScale(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: 18, alignment: .center)
            .padding(12)
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
            // Trigger a subtle capture animation on the icon
            captureTick &+= 1
            menuBarVM.startTapped()
        }
        .help("Capture & mark the screen (Set Hotkey in Settings)")
    }
}

private struct StartMarkLogo: View {
    let isHovering: Bool
    let symbolName: String
    var captureTick: Int = 0
    
    @State private var flashOpacity: CGFloat = 0
    @State private var recoilScale: CGFloat = 1
    
    var body: some View {
        ZStack {
            // Single container that morphs rather than switching views
            RoundedRectangle(cornerRadius: isHovering ? 5.5 : 5)
                .stroke(.white.opacity(isHovering ? 0.25 : 0.12),
                        lineWidth: isHovering ? 1.2 : 1)
                .frame(width: isHovering ? 18 : 16,
                       height: isHovering ? 18 : 16)
            
            // Center icon - stays in same position
            Image(systemName: symbolName)
                .font(.system(size: isHovering ? 12.5 : 12,
                              weight: isHovering ? .medium : .regular))
                .foregroundStyle(.white)
            
            // Capture flash overlay
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .opacity(Double(flashOpacity))
        }
        .frame(width: 18, height: 18) // Fixed container size
        .scaleEffect(recoilScale)
        .animation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0),
                   value: isHovering)
        .accessibilityHidden(true)
        .onChange(of: captureTick) {
            playCaptureAnimation()
        }
    }
    
    private func playCaptureAnimation() {
        // Single smooth recoil animation
        withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
            recoilScale = 0.92
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                recoilScale = 1.0
            }
        }
        
        // Clean flash
        withAnimation(.easeOut(duration: 0.08)) {
            flashOpacity = 0.8
        }
        withAnimation(.easeIn(duration: 0.15).delay(0.08)) {
            flashOpacity = 0
        }
    }
}
