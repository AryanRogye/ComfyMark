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
                            VStack{
                                topRow
                                Spacer()
                            }
                        }
                        .onTapGesture {
                            stageVM.imageTapped()
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
    
    private var topRow: some View {
        HStack {
            Spacer()
            Button(action: stageVM.exitTapped) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }
}
