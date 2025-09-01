//
//  MenuBarView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

struct MenuBarView: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    var body: some View {
        VStack {
            VStack {
                startButton
                settingsSection()
            }
            .padding()
        }
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8, y: 2)
        .alert("Error", isPresented: menuBarVM.hasError, presenting: menuBarVM.errorMessage) { _ in
            Button("OK") { menuBarVM.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }
    
    private var startButton: some View {
        MenuBarViewButton {
            Label("Start", systemImage: "play.fill")
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            menuBarVM.startButtonTapped
                            ? Color.red : Color.blue
                        )
                }
        } action: {
            menuBarVM.startTapped()
        }
    }
    
    @Namespace var ns
    @State private var isHoveringOverSettings = false
    
    @ViewBuilder
    private func settingsSection() -> some View {
        HStack {
            if isHoveringOverSettings {
                settingsLogo
            }
            exitButton
            
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isHoveringOverSettings)
        .onHover { isHoveringOverSettings = $0 }
    }
    
    private var exitButton: some View {
        MenuBarViewButton {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isHoveringOverSettings
                    ? Color.red
                    : Color.gray.opacity(0.7)
                )
                .matchedGeometryEffect(id: "exitButton", in: ns)
                .overlay {
                    Label(
                        isHoveringOverSettings
                        ? "Quit"
                        : "Settings",
                        systemImage: isHoveringOverSettings
                        ? "power"
                        : "gear"
                    )
                    .foregroundStyle(.white)
                }
        } action: {
            if isHoveringOverSettings {
                NSApp.terminate(nil)
            }
        }
        .frame(height: 40)
    }
    
    private var settingsLogo: some View {
        MenuBarViewButton {
            Circle()
                .fill(Color.gray.opacity(0.7))
                .matchedGeometryEffect(id: "settingsBackground", in: ns)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
        } action: { menuBarVM.openSettings() }
    }
}


#Preview {
    MenuBarView(
        menuBarVM: MenuBarViewModel()
    )
}
