//
//  SelectionRect.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

import SwiftUI

struct SelectionRect: View {
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
