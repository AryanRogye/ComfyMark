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

struct ExportDocument: FileDocument {
    // Support reading/writing the same types we export
    static var readableContentTypes: [UTType] = ExportFormat.allCases.map { $0.utType }
    static var writableContentTypes: [UTType] = ExportFormat.allCases.map { $0.utType }

    let data: Data
    // Chosen at export time; propagated into .fileExporter
    let contentType: UTType

    // Export-only initializer
    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    // Required by FileDocument conformance; keeps things valid if reading is ever used
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
        self.contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Enum Represents Formats the User might choose
enum ExportFormat : String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case pdf = "PDF"
//    case svg = "SVG"
    
    /// Easy Way for Fast Description
    var export_description: String {
        "Export as \(self.rawValue)"
    }
    
    var fileExtension: String {
        switch self {
        case .png:  return "png"
        case .jpeg: return "jpg"
        case .pdf:  return "pdf"
        }
    }
    
    var utType: UTType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .pdf:
            return .pdf
        }
    }
    
    func defaultFilename(base: String = "Screenshot") -> String {
        "\(base).\(fileExtension)"
    }
}

/// Represents the Final Exported Data we send
enum ExportedData {
    case data(Data)
}

protocol ExportProviding {
    func export(_ cgimage: CGImage, format: ExportFormat) -> ExportedData?
}

class ExportService: ExportProviding {
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
