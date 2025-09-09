//
//  MenuBarHistory.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import SwiftUI

// MARK: - Menu Bar History
struct MenuBarHistoryView: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    var body: some View {
        VStack {
            /// This is the Button That Is Default Shown
            MenuBarHistoryButton(menuBarVM: menuBarVM)
                
            if menuBarVM.isShowingMultipleDelete {
                MenuBarMultipleDelete(menuBarVM: menuBarVM)
            } // If Button is pressed
            else if menuBarVM.isShowingHistory {
                MenuBarScreenshotView(menuBarVM: menuBarVM)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: menuBarVM.isShowingHistory) { _, value in
            if !value {
                /// If We Show Multiple Delete Just Cancel It
                menuBarVM.isShowingMultipleDelete = false
                menuBarVM.selectedHistoryIndex = nil
                menuBarVM.selectedHistoryIndexs.removeAll()
            }
        }
    }
}
