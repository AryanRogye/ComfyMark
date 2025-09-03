//
//  GeneralSettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import SwiftUI

struct GeneralSettings: View {
    
    @EnvironmentObject var generalVM : GeneralViewModel
    
    var body: some View {
        SettingsContainerView {
            SettingsSection {
                showDockIcon
            }
        }
    }
    
    private var showDockIcon: some View {
        HStack {
            Text("Show Dock Icon")
            Spacer()
            Toggle("Show Dock Icon", isOn: $generalVM.appSettings.showDockIcon)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
}
