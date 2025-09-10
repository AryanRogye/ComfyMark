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
            Color.black.opacity(0.7)

            /// Selection rectangle If User decides to drag
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
        .contentShape(Rectangle())
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
            Button(action: selectionOverlayVM.captureSelection) {
                Text("Capture")
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel("Take A Capture Of The Selected Area")
            
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
