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
                MenuBarStart(
                    menuBarVM: menuBarVM
                )
                
                MenuBarAppStats(
                    menuBarVM: menuBarVM
                )
                
                MenuBarHistoryView(
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
    
    
    // MARK: - Setting Section
    @ViewBuilder
    private func settingsSection() -> some View {
        HStack {
            if menuBarVM.appSettings.menuBarPowerButtonSide == .left {
                if isHoveringOverSettings {
                    powerLogo
                }
            }
            
            MenuBarSettings(menuBarVM: menuBarVM)
            
            if menuBarVM.appSettings.menuBarPowerButtonSide == .right {
                if isHoveringOverSettings {
                    powerLogo
                }
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: isHoveringOverSettings)
        .onHover { isHoveringOverSettings = $0 }
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
    let appSettings       = AppSettings()
    var menuBarVM: MenuBarViewModel = MenuBarViewModel(appSettings: appSettings, screenshotManager: screenshotManager)
    
    
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
