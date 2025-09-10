//
//  SelectionOverlay.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

import SwiftUI

struct SelectionOverlay: View {
    @ObservedObject var selectionOverlayVM: SelectionOverlayViewModel

    var body: some View {
        ZStack {
            // Dim the screen
            Color.black.opacity(0.5)

            // Selection rectangle overlay
            if let rect = selectionOverlayVM.selectionRect {
                SelectionRect(rect: rect, sizeText: selectionOverlayVM.selectionSizeText)
            }

            // Top bar with close
            VStack {
                topRow
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle()) // ensure drags hit everywhere
        .gesture(dragGesture)
        .onExitCommand(perform: selectionOverlayVM.exit)
    }

    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // startLocation is stable for the whole drag
                selectionOverlayVM.beginDrag(at: value.startLocation)
                selectionOverlayVM.updateDrag(to: value.location)
            }
            .onEnded { value in
                selectionOverlayVM.endDrag(at: value.location)
            }
    }
    
    private var topRow: some View {
        HStack {
            Spacer()
            Button(action: selectionOverlayVM.exit) {
                Image(systemName: "xmark")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Close Selection Overlay")
        }
        .padding()
    }
}

// MARK: - Selection Rect View
private struct SelectionRect: View {
    let rect: CGRect
    let sizeText: String?

    var body: some View {
        Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .background(
                Rectangle().fill(Color.white.opacity(0.15))
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(alignment: .topLeading) {
                if let sizeText = sizeText {
                    Text(sizeText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(6)
                }
            }
    }
}
