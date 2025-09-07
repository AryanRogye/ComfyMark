//
//  MenuBarBehavior.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI


enum MenuBarPowerButtonSide: String, CaseIterable {
    case left = "Left"
    case right = "Right"
}

struct MenuBarBehavior: View {
    
    @EnvironmentObject var behaviorVM : BehaviorViewModel

    var body: some View {
        HStack {
            Picker("Power Button Side", selection: $behaviorVM.appSettings.menuBarPowerButtonSide) {
                ForEach(MenuBarPowerButtonSide.allCases, id: \.self) { side in
                    Text(side.rawValue).tag(side)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
}
