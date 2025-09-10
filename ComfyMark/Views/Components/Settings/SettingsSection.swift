//
//  SettingsSection.swift
//  ComfyTab
//
//  Created by Aryan Rogye on 8/15/25.
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    var content: Content
    var title: String?
    
    init(
        _ title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        GroupBox(
            label: Text(title ?? "")
                .font(.headline)
                .foregroundColor(.primary)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }
}
