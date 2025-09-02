//
//  Export.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import SwiftUI
import UniformTypeIdentifiers


// MARK: - FileDocument Wrapper
/// A simple `FileDocument` that wraps raw export `Data` with a
/// specified Uniform Type Identifier for use with SwiftUI's
/// `fileExporter`. Reading support is implemented to satisfy
/// `FileDocument` conformance, though the app currently uses it
/// only for writing/exports.
struct ExportDocument: FileDocument {
    /// The UTTypes this document can read. Mirrors supported export types.
    static var readableContentTypes: [UTType] = ExportFormat.allCases.map { $0.utType }
    /// The UTTypes this document can write. Mirrors supported export types.
    static var writableContentTypes: [UTType] = ExportFormat.allCases.map { $0.utType }
    
    /// The raw file data to be written by the exporter.
    let data: Data
    /// The content type/UTI for the data. Chosen at export time and
    /// propagated into SwiftUI's `.fileExporter`.
    let contentType: UTType
    
    /// Creates an export-only document with data and content type.
    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }
    
    /// Required by `FileDocument` conformance. Initializes from a
    /// read configuration; retains compatibility if reading is
    /// introduced in the future.
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
        self.contentType = configuration.contentType
    }
    
    /// Produces a `FileWrapper` that writes the raw export `data`.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}


// MARK: - Export Format
/// The set of export formats presented to the user.
enum ExportFormat : String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case pdf = "PDF"
    //    case svg = "SVG"
    
    /// User-facing description for use in menus/actions.
    var export_description: String {
        "Export as \(self.rawValue)"
    }
    
    /// The file extension associated with the format, without dot.
    var fileExtension: String {
        switch self {
        case .png:  return "png"
        case .jpeg: return "jpg"
        case .pdf:  return "pdf"
        }
    }
    
    /// The Uniform Type Identifier corresponding to the format.
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
    
    /// Provides a default filename for the format using the given base.
    /// - Parameter base: The filename stem (defaults to "Screenshot").
    /// - Returns: A filename like "Screenshot.png".
    func defaultFilename(base: String = "Screenshot") -> String {
        "\(base).\(fileExtension)"
    }
    
    // MARK: - Export Icons/Colors
    /// An SF Symbols name representing the format for UI.
    var iconName: String {
        switch self {
        case .png:  return "photo"
        case .jpeg: return "photo.on.rectangle"
        case .pdf:  return "doc.richtext"
        }
    }
    
    /// A representative color for the format's UI affordances.
    var iconColor: Color {
        switch self {
        case .png:  return .green
        case .jpeg: return .orange
        case .pdf:  return .red
        }
    }
}
