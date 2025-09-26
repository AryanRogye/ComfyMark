//
//  ImageStager.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/12/25.
//

import SwiftUI

struct ImageStager: View {
    
    @ObservedObject var stageVM: ImageStageViewModel
    
    var body: some View {
        ZStack {
            Color.clear
            if let img = stageVM.image {
                VStack {
                    Spacer()
                    Image(decorative: img, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .border(.black, width: 1)
                        .shadow(radius: 2.5)
                        .onDrag {
                            stageVM.onDrag()
                        }
                        .overlay {
                            imageOverlay
                        }
                        .onTapGesture {
                            stageVM.imageTapped()
                        }
                        .onHover {
                            stageVM.isHovering = $0
                        }
                        .onChange(of: stageVM.isHovering) { _, newValue in
                            stageVM.handleHover(newValue)
                        }
                        .animation(.spring, value: stageVM.showTapGesture)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                            removal: .scale(scale: 0.1).combined(with: .opacity)
                        ))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    
    private var imageOverlay: some View {
        ZStack {
            VStack {
                topRow
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            if stageVM.showTapGesture {
                Button(action: stageVM.imageTapped) {
                    Text("Tap to edit")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: stageVM.showTapGesture ? 4 : 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var topRow: some View {
        HStack {
            Spacer()
            Button(action: stageVM.exitTapped) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(radius: stageVM.showTapGesture ? 4 : 2)
            }
            .buttonStyle(.plain)
            .scaleEffect(stageVM.showTapGesture ? 0.9 : 0.8)
        }
        .padding(8)
    }    
}
