//
//  Image.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import SwiftUI

extension Image {
    func iconWithRectangle(
        size: CGFloat = 20,          // square background size
        glyph: CGFloat = 14,         // icon (glyph) size
        corner: CGFloat = 6,         // rounded rect radius
        bg: Color = .accentColor,
        glyphColor: Color = .white
    ) -> some View {
        self
            .renderingMode(.template)     // ensure tintable
            .resizable()
            .scaledToFit()
            .frame(width: glyph, height: glyph)   // 1) size the glyph
            .foregroundStyle(glyphColor)
            .frame(width: size, height: size)     // 2) center it in a square
            .background(                         // 3) put bg behind the square
                RoundedRectangle(cornerRadius: corner)
                    .fill(bg)
            )
    }
}
