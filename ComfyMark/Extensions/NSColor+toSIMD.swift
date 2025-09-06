//
//  Color.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/5/25.
//

import AppKit

extension NSColor {
    /// Returns straight (non-premultiplied) RGBA in 0…1
    func toSIMD() -> SIMD4<Float> {
        // Make sure we’re in device RGB, not a color profile like P3/CMYK
        let c = self.usingColorSpace(.deviceRGB) ?? self
        return SIMD4(Float(c.redComponent),
                     Float(c.greenComponent),
                     Float(c.blueComponent),
                     Float(c.alphaComponent))
    }
}
