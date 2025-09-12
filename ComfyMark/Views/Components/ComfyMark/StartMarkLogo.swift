//
//  StartMarkLogo.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/11/25.
//

import SwiftUI

struct StartMarkLogo: View {
    
    let isHovering: Bool
    let symbolName: String
    var captureTick: Int = 0
    
    @StateObject private var startMarkVM: StartMarkLogoViewModel = StartMarkLogoViewModel()
    
    
    var body: some View {
        ZStack {
            // Single container that morphs rather than switching views
            RoundedRectangle(cornerRadius: isHovering ? 5.5 : 5)
                .stroke(.white.opacity(isHovering ? 0.25 : 0.12),
                        lineWidth: isHovering ? 1.2 : 1)
                .frame(width: isHovering ? 18 : 16)

            // Center icon - stays in same position
            Image(systemName: symbolName)
                .font(.system(size: isHovering ? 12.5 : 12,
                              weight: isHovering ? .medium : .regular))
                .foregroundStyle(.white)
            
            // Capture flash overlay
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .opacity(Double(startMarkVM.flashOpacity))
        }
        .frame(width: 18) // Fixed container size
        .scaleEffect(startMarkVM.recoilScale)
        .animation(.spring(response: 0.25, dampingFraction: 0.8, blendDuration: 0),
                   value: isHovering)
        .accessibilityHidden(true)
        .onChange(of: captureTick) {
            startMarkVM.playCaptureAnimation()
        }
    }
}

extension StartMarkLogo {
    @MainActor
    private final class StartMarkLogoViewModel: ObservableObject {
        
        @Published var flashOpacity: CGFloat = 0
        @Published var recoilScale: CGFloat = 1
        
        func playCaptureAnimation() {
            // Single smooth recoil animation
            withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                recoilScale = 0.92
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { [weak self] in
                    guard let self = self else { return }
                    self.recoilScale = 1.0
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
}
