//
//  ExportService.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Models
/// Container for data produced by an export operation.
///
/// Keeping this as an enum allows future expansion (e.g., file URL,
/// stream handle) without changing the protocol surface.
enum ExportedData {
    case data(Data)
}

// MARK: - Protocol
/// Abstraction for converting a `CGImage` into serialized file data.
///
/// Implementations may choose supported formats and how they map
/// to concrete encoders (e.g., `NSBitmapImageRep`, PDF contexts).
protocol ExportProviding {
    /// Serializes a `CGImage` into the specified `ExportFormat`.
    /// - Parameters:
    ///   - cgimage: The source image to encode.
    ///   - format: The desired output format.
    /// - Returns: `ExportedData` on success; `nil` if encoding fails.
    func export(_ cgimage: CGImage, format: ExportFormat) -> ExportedData?
}

// MARK: - Service
/// Default exporter for PNG, JPEG, and PDF formats.
class ExportService: ExportProviding {
    /// Encodes the provided `CGImage` to the requested format.
    ///
    /// - PNG: Uses `NSBitmapImageRep` with `.png` representation.
    /// - JPEG: Uses `NSBitmapImageRep` with compression factor (0.0–1.0).
    /// - PDF: Creates a single-page PDF sized to the image dimensions
    ///   and draws the image into that page.
    public func export(
        _ cgimage: CGImage,
        format: ExportFormat
    ) -> ExportedData? {
        switch format {
        case .png:
            let rep = NSBitmapImageRep(cgImage: cgimage)
            guard let data = rep.representation(using: .png, properties: [:]) else { return nil }
            return .data(data)
            
        case .jpeg:
            let jpegQuality = 0.9
            let rep = NSBitmapImageRep(cgImage: cgimage)
            let q = max(0, min(1, jpegQuality))
            guard let data = rep.representation(using: .jpeg, properties: [.compressionFactor: q]) else { return nil }
            return .data(data)
            
        case .pdf:
            let w = CGFloat(cgimage.width), h = CGFloat(cgimage.height)
            var box = CGRect(x: 0, y: 0, width: w, height: h)
            let m = NSMutableData()
            guard let consumer = CGDataConsumer(data: m as CFMutableData),
                  let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return nil }
            ctx.beginPDFPage(nil)
            ctx.draw(cgimage, in: box)
            ctx.endPDFPage()
            ctx.closePDF()
            return .data(m as Data)
        }
    }
}
