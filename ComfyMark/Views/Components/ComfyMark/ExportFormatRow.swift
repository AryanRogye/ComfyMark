//
//  ExportFormatRow.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import SwiftUI

// MARK: - Export Popover Row, this is used inside the Toolbar Export
struct ExportFormatRow: View {
    let format: ExportFormat
    let iconName: String
    let iconColor: Color
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        ComfyMarkButton {
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
