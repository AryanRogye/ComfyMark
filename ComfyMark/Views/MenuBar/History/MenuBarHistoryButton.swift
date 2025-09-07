//
//  MenuBarHistoryButton.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI

struct MenuBarHistoryButton: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    var body: some View {
        MenuBarMaterialButton {
            HStack {
                Label("View History", systemImage: "clock")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.compact.down")
                    .resizable()
                    .frame(width: 11, height: 7)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(menuBarVM.isShowingHistory ? 180 : 0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.9),
                               value: menuBarVM.isShowingHistory)
            }
        } action: {
            menuBarVM.isShowingHistory.toggle()
        }
    }
}
