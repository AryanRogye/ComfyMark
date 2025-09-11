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
                Button {
                    if !EditorState.nonOneClickStates.contains(state) {
                        comfyMarkVM.currentState = state
                    }
                    switch state {
                    case .undo: comfyMarkVM.undo()
                    case .redo: comfyMarkVM.redo()
                    case .brush_radius: comfyMarkVM.shouldShowRadius()
                    default: break
                    }
                } label: {
                    Image(systemName: state.icon)
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(
                            Circle().fill(comfyMarkVM.currentState == state ? Color.blue : Color.gray)
                        )
                }
                .buttonStyle(.plain)
                // Attach popover to the Button (not inside the label)
                .popover(
                    isPresented: Binding(
                        get: { state == .brush_radius && comfyMarkVM.shouldShowBrushRadiusPopover },
                        set: { comfyMarkVM.shouldShowBrushRadiusPopover = $0 }
                    ),
                    attachmentAnchor: .rect(.bounds),
                    arrowEdge: .bottom
                ) {
                    radiusPopover
                }
            }
        }
    }
    
    private var radiusPopover: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Radius")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(comfyMarkVM.brushRadius))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(value: $comfyMarkVM.brushRadius, in: 1...64, step: 1) {
                Text("Radius")
            } minimumValueLabel: {
                Text("1")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Text("64")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .accentColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .frame(width: 240)
    }
}
