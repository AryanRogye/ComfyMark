//
//  ComfyMarkToolbar.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ComfyMarkToolbar: View {
    
    @ObservedObject var comfyMarkVM: ComfyMarkViewModel
    
    var body: some View {
        HStack {
            Spacer()
            cancelButton
            saveButton
            exportButton()
        }
        .padding(.horizontal, 8)
    }
    
    @State private var showExportMenu: Bool = false
    @State private var isHoveringExport: Bool = false
   
    
    // MARK: - Export Button
    @ViewBuilder
    private func exportButton() -> some View {
        ZStack {
            MenuBarViewButton {
                Image(systemName: "square.and.arrow.down")
                    .imageScale(.medium)
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.gray.opacity(isHoveringExport ? 0.85 : 0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .shadow(color: Color.black.opacity(isHoveringExport ? 0.18 : 0.12), radius: 8, x: 0, y: 1)
            } action: {
                showExportMenu.toggle()
            }
            .onHover { isHovering in
                isHoveringExport = isHovering
            }
            /// PopOver For Export Option
            .popover(
                isPresented: $showExportMenu,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .bottom
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export As")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        ExportFormatRow(
                            format: format,
                            iconName: iconName(for: format),
                            iconColor: iconColor(for: format)
                        ) {
                            comfyMarkVM.onExport(format)
                            showExportMenu = false
                        }
                    }
                }
                .padding(10)
                .frame(minWidth: 200)
            }
        }
        .fileExporter(
            isPresented: $comfyMarkVM.shouldExport,
            document: comfyMarkVM.exportDocument ?? ExportDocument(data: Data(), contentType: .png),
            contentType: comfyMarkVM.exportDocument?.contentType ?? .png,
            defaultFilename: comfyMarkVM.exportSuggestedName("Screenshot")
        ) { result in
            if case let .failure(error) = result {
                // optional: surface an alert
                print("Export failed:", error)
            }
        }
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        MenuBarViewButton {
            Text("Cancel")
                .foregroundStyle(.white)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.7))
                }
        } action: {
            comfyMarkVM.onCancel()
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        MenuBarViewButton {
            Text("Save")
                .foregroundStyle(.white)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                }
            
        } action: {
            
        }
    }
}

#Preview {
    ComfyMarkToolbar(comfyMarkVM: ComfyMarkViewModel(
        image: CGImage.placeholder(),
        windowID: ""
    ))
}


extension CGImage {
    static func placeholder(width: Int = 1, height: Int = 1) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            fatalError("Could not create CGContext for placeholder CGImage")
        }
        
        ctx.setFillColor(CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return ctx.makeImage()!
    }
}

// MARK: - Export Popover Row
private struct ExportFormatRow: View {
    let format: ExportFormat
    let iconName: String
    let iconColor: Color
    let action: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        MenuBarViewButton {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("." + format.fileExtension.uppercased())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovering ? Color.white.opacity(0.08) : Color.clear)
            }
        } action: {
            action()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Export Icons/Colors
private func iconName(for format: ExportFormat) -> String {
    switch format {
    case .png:  return "photo"
    case .jpeg: return "photo.on.rectangle"
    case .pdf:  return "doc.richtext"
    }
}

private func iconColor(for format: ExportFormat) -> Color {
    switch format {
    case .png:  return .green
    case .jpeg: return .orange
    case .pdf:  return .red
    }
}
