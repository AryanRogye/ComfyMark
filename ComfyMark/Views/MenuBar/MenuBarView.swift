//
//  MenuBarView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

struct MenuBarView: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    /// For Settings
    @Namespace var ns
    @State private var isHoveringOverSettings = false

    var body: some View {
        VStack {
            VStack {
                
                startButton
                
                MenuBarAppStats(
                    menuBarVM: menuBarVM
                )
                
                MenuBarHistory(
                    menuBarVM: menuBarVM
                )
                
                Divider().padding(.horizontal)
                
                settingsSection()
            }
            .padding()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.clear)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8, y: 2)
        .alert("Error", isPresented: menuBarVM.hasError, presenting: menuBarVM.errorMessage) { _ in
            Button("OK") { menuBarVM.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }
    
    // MARK: - Start Button
    private var startButton: some View {
        ComfyMarkButton {
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
    
    
    // MARK: - Setting Section
    @ViewBuilder
    private func settingsSection() -> some View {
        HStack {
            if isHoveringOverSettings {
                powerLogo
            }
            MenuBarSettings(menuBarVM: menuBarVM)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isHoveringOverSettings)
        .onHover { isHoveringOverSettings = $0 }
    }
    
    // MARK: - Exit Button
    private var settingsButton: some View {
        ComfyMarkButton {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.7))
                .matchedGeometryEffect(id: "settingsBackground", in: ns)
                .overlay {
                    Label("Settings", systemImage:"gear")
                        .foregroundStyle(.white)
                }
        } action: {
            menuBarVM.openSettings()
        }
        .frame(height: 40)
    }
    
    // MARK: - Settings Logo
    private var powerLogo: some View {
        ComfyMarkButton {
            Circle()
                .fill(Color.red)
                .frame(width: 24, height: 24)
                .matchedGeometryEffect(id: "exitButton", in: ns)
                .overlay {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
        } action: {
            if isHoveringOverSettings {
                NSApp.terminate(nil)
            }
        }
    }
}


#Preview {
    let screenshotManager = ScreenshotManager(saving: SavingService())
    var menuBarVM: MenuBarViewModel = MenuBarViewModel(screenshotManager: screenshotManager)
    
    
    ZStack {
        
        Color.black.opacity(0.3)
            .frame(width: menuBarVM.menuBarWidth, height: menuBarVM.menuBarHeight)
        
        MenuBarView(
            menuBarVM: menuBarVM
        )
        .frame(width: menuBarVM.menuBarWidth, height: menuBarVM.menuBarHeight)
        .background(.thinMaterial)
    }
    .frame(width: menuBarVM.menuBarWidth, height: menuBarVM.menuBarHeight)
}
