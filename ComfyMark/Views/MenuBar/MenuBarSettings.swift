//
//  MenuBarSettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI

struct MenuBarSettings: View {
    
    @ObservedObject var menuBarVM: MenuBarViewModel
    
    var body: some View {
        MenuBarMaterialButton {
            HStack {
                Label("Settings", systemImage: "clock")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } action: {
            withAnimation(.bouncy) {
                menuBarVM.isShowingHistory.toggle()
            }
        }

    }
}
