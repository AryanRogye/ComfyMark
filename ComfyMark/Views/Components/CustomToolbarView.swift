//
//  CustomToolbarView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/1/25.
//

import SwiftUI

extension NSToolbarItem.Identifier {
    static let customToolbarItem = NSToolbarItem.Identifier("CustomToolbarItem")
}

struct CustomToolbarView<Content: View, ToolbarContent: View>: NSViewRepresentable {
    
    var content: Content
    var toolbar: ToolbarContent
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder toolbar: () -> ToolbarContent
    ) {
        self.content = content()
        self.toolbar = toolbar()
    }
    
    func makeNSView(context: Context) -> some NSView {
        let nsView = NSView()
        let hostingController = NSHostingController(rootView: content)
        
        // Add the hosting controller's view
        nsView.addSubview(hostingController.view)
        
        // Set up constraints so it fills the container
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: nsView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
        ])
        
        // Set up the custom toolbar when the view appears in a window
        DispatchQueue.main.async {
            self.setupCustomToolbar(for: nsView, context: context)
        }
        
        return nsView
    }
    
    private func setupCustomToolbar(for nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        
        let toolbar = NSToolbar(identifier: "CustomToolbar")
        toolbar.delegate = context.coordinator
        toolbar.displayMode = .iconAndLabel
        
        window.toolbar = toolbar
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(toolbarContent: toolbar)
    }
    
    class Coordinator: NSObject, NSToolbarDelegate {
        let toolbarContent: ToolbarContent
        
        init(toolbarContent: ToolbarContent) {
            self.toolbarContent = toolbarContent
        }
        
        func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
            
            if itemIdentifier == .customToolbarItem {
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                
                let hostingController = NSHostingController(rootView: toolbarContent)
                item.view = hostingController.view
                
                // Make the hosting view expand to fill available space
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                
                // Set very low hugging priority so it wants to expand
                hostingController.view.setContentHuggingPriority(.init(1), for: .horizontal)
                hostingController.view.setContentCompressionResistancePriority(.init(1), for: .horizontal)
                
                return item
            }
            
            return nil
        }
        
        func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [.customToolbarItem]
        }
        
        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            return [.customToolbarItem]
        }
    }
}
