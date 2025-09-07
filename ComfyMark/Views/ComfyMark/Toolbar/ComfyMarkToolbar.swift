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
            ToolbarEditorStateView(
                comfyMarkVM: comfyMarkVM
            )
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
            ComfyMarkButton {
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
                            iconName: format.iconName,
                            iconColor: format.iconColor
                        ) {
                            /// What we do on the export
                            comfyMarkVM.onExport(format)
                            showExportMenu = false
                        }
                    }
                }
                .padding(10)
                .frame(minWidth: 200)
            }
        }
        /// File Exporter for when we export
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
        ComfyMarkButton {
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
        ComfyMarkButton {
            Text("Save")
                .foregroundStyle(.white)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue)
                }
            
        } action: {
            comfyMarkVM.onSave()
        }
    }
}

#Preview {
    ComfyMarkToolbar(
        comfyMarkVM: ComfyMarkViewModel(
            image: CGImage.placeholder(),
            windowID: ""
        )
    )
}
