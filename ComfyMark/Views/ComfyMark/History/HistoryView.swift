//
//  HistoryView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import SwiftUI

struct HistoryView: View {
    
    @ObservedObject var historyManager : HistoryManager
    
    @State private var hovering = false
    @State private var selectedItem: HistoryItem?
    
    var geo: GeometryProxy
    
    var body: some View {
        ViewSidebar(geo) {
            
            ScrollView {
                disclosureGroup(label: "History") {
                    viewForStack(historyManager.items)
                }
                
                disclosureGroup(label: "Undo") {
                    viewForStack(historyManager.undoStack)
                }
                
                disclosureGroup(label: "Redo") {
                    viewForStack(historyManager.redoStack)
                }
            }
            
        }
    }
    
    @ViewBuilder
    func disclosureGroup<Content: View>(label: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        DisclosureGroup {
            content()
        } label: {
            Text(label)
        }
    }
    
    @ViewBuilder
    private func viewForStack(_ stack: [HistoryItem]) -> some View {
        ForEach(stack) { item in
            viewForItem(item)
        }
    }
    
    @ViewBuilder
    private func viewForItem(_ item: HistoryItem) -> some View {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 26, height: 26)
                
                VStack {
                    Text(item.operation.type.label)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(item.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill((hovering && selectedItem == item) ? Color.accentColor.opacity(0.15) : Color.clear
                    )
            }
            .onHover { hover in
                hovering = hover
                selectedItem = item
            }
    }
    
    
}
