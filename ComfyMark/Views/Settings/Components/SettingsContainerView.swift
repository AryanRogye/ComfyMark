//
//  SettingsContainerView.swift
//  ComfyTab
//
//  Created by Aryan Rogye on 8/15/25.
//

import SwiftUI

struct SettingsContainerView<Content: View>: View {
    var content: Content
    
    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}
