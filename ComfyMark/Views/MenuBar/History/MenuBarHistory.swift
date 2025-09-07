//
//  MenuBarHistory.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import SwiftUI

// MARK: - Menu Bar History
struct MenuBarHistory: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    var body: some View {
        VStack {
            /// This is the Button That Is Default Shown
            MenuBarHistoryButton(menuBarVM: menuBarVM)
            
            // If Button is pressed
            if menuBarVM.isShowingHistory {
                ScreenshotHistoryView(menuBarVM: menuBarVM)
            }
        }
    }
}
