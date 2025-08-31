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
                settingsButton
            }
            .padding()
        }
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8, y: 2)
    }
    
    private var startButton: some View {
        MenuBarViewButton {
            Label("Start", systemImage: "play.fill")
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                }
        } action: {
            
        }
    }
    
    private var settingsButton : some View {
        MenuBarViewButton {
            Text("Settings")
                .foregroundStyle(.white)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.7))
                }
        } action: {
            menuBarVM.openSettings()
        }
    }
}


#Preview {
    MenuBarView(
        menuBarVM: MenuBarViewModel()
    )
}
