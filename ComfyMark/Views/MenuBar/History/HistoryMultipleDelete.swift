//
//  HistoryListMultipleDelete.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/7/25.
//

import SwiftUI

struct MenuBarMultipleDelete: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel

    var body: some View {
        VStack {
            ScrollView {
                content
            }
            footer
        }
    }
    
    
    private var footer: some View {
        MenuBarMaterialButton {
            HStack {
                Label("Cancel", systemImage: "xmark")
                    .foregroundStyle(.primary)
                Spacer()
                
                if !menuBarVM.selectedItemsIsEmtpy {
                    Button("Delete \(menuBarVM.selectedItems.count)", role: .destructive) {
                        Task { await menuBarVM.performMassDelete() }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(menuBarVM.isDeleting)
                }
                
            }
        } action: {
            menuBarVM.isShowingMultipleDelete = false
            menuBarVM.selectedHistoryIndexs.removeAll()
            menuBarVM.selectedHistoryIndex = nil
        }
        .frame(maxWidth: .infinity)
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            if menuBarVM.selectedItems.isEmpty {
                Text("No items selected")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            } else {
                HStack(spacing: 8) {
                    if menuBarVM.isDeleting {
                        ProgressView().controlSize(.small)
                    }
                    Text("Delete \(menuBarVM.selectedItems.count) selected screenshot\(menuBarVM.selectedItems.count == 1 ? "" : "s")?")
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

                LazyVStack(spacing: 6) {
                    ForEach(menuBarVM.selectedItems, id: \.id) { item in
                        HStack(spacing: 8) {
                            Image(nsImage: item.thumbnail)
                                .resizable()
                                .interpolation(.medium)
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(item.url.lastPathComponent)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.05))
                        )
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}


#Preview {
    MenuBarMultipleDelete(menuBarVM: MenuBarViewModel(appSettings: AppSettings(), screenshotManager: ScreenshotManager(saving: SavingService())))
        .frame(width: 200, height: 100)
}
