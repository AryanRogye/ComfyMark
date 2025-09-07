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
                Label("Settings", systemImage: "gear")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } action: {
            menuBarVM.openSettings()
        }

    }
}
