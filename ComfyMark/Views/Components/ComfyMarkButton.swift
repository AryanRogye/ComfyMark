//
//  ComfyMarkButton.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI



struct ComfyMarkButton<Content: View>: View {
    
    var content: () -> Content
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            content()
        }
        .buttonStyle(.plain)
    }
}
