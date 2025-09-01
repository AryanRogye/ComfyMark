//
//  ComfyMarkToolbar.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import SwiftUI

struct ComfyMarkToolbar: View {
    
    @ObservedObject var comfyMarkVM: ComfyMarkViewModel
    
    var body: some View {
        HStack {
            Spacer()
            cancelButton
            saveButton
        }
    }
    
    private var cancelButton: some View {
        MenuBarViewButton {
            Text("Cancel")
                .foregroundStyle(.white)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.7))
                }
        } action: {
            comfyMarkVM.onCancel()
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
