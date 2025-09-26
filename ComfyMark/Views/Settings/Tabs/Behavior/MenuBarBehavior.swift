//
//  MenuBarBehavior.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI


struct MenuBarBehaviorSettings: View {
    
    @EnvironmentObject var behaviorVM : BehaviorViewModel

    var body: some View {
        SettingsSection("Menu Bar Behavior") {
            PowerButtonSidePicker()
        }
    }
}

struct PowerButtonSidePicker: View {
    
    @EnvironmentObject var behaviorVM : BehaviorViewModel
    @State private var selectedSide: MenuBarPowerButtonSide = .left
    
    var body: some View {
        HStack {
            Text("Power Button Side")
            Spacer()
            Picker("Power Button Side", selection: $selectedSide) {
                ForEach(MenuBarPowerButtonSide.allCases, id: \.self) { side in
                    Text(side.rawValue).tag(side)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: selectedSide) { _, value in
                behaviorVM.appSettings.menuBarPowerButtonSide = value
            }
        }
        .padding(.horizontal)
        .onAppear {
            selectedSide = behaviorVM.appSettings.menuBarPowerButtonSide
        }
    }
}
