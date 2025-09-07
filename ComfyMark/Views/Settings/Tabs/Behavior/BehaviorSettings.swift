//
//  BehaviorSettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI

struct BehaviorSettings: View {
    

    var body: some View {
        SettingsContainerView {
            menuBarBehavior
        }
    }
    
    private var menuBarBehavior: some View {
        SettingsSection("Menu Bar Behavior") {
            MenuBarBehavior()
        }
    }
}
