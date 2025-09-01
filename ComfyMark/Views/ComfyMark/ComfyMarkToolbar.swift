//
//  ComfyMarkToolbar.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import SwiftUI

struct ComfyMarkToolbar: View {
    var body: some View {
        HStack {
            Spacer()
            saveButton
        }
    }
    
    private var saveButton: some View {
        MenuBarViewButton {
            Text("Save")
                .foregroundStyle(.white)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                }
            
        } action: {
            
        }
    }
}
