//
//  ComfyMarkView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import SwiftUI

struct ComfyMarkView: View {
    
    @ObservedObject var comfyMarkVM : ComfyMarkViewModel
    
    var body: some View {
        VStack {
            Image(decorative: comfyMarkVM.image, scale: 1.0, orientation: .up)
                .resizable()
                .frame(width: 300, height: 300)
        }
        .frame(width: 300, height: 300)
    }
}
