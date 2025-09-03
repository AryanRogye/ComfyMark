//
//  ToolbarEditorStateView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import SwiftUI

struct ToolbarEditorStateView: View {
    
    @ObservedObject var comfyMarkVM: ComfyMarkViewModel
    
    var body: some View {
        HStack {
            ForEach(EditorState.allCases, id: \.self) { state in
                Button(action: {
                    comfyMarkVM.currentState = state
                    print("Set State: \(state)")
                }) {
                    Image(systemName: state.icon)
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background {
                            Circle()
                                .fill(
                                    comfyMarkVM.currentState == state ? Color.blue : Color.gray
                                )
                        }
                }
            }
        }
    }
}
