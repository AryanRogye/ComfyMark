//
//  MenuBarCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import AppKit
import SwiftUI

@MainActor
class MenuBarCoordinator: NSObject {
    
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    
    var onSettingsTapped: (() -> Void)?

    override init() {
        super.init()
    }
    
    public func start(
        onSettingsTapped: @escaping () -> Void
    ) {
        
        /// Create The MenuBarViewModel
        let menuBarVM = MenuBarViewModel()
        menuBarVM.onSettingsTapped = onSettingsTapped
        
        /// Start Making Menu Bar Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Annotate")
            btn.action = #selector(togglePopover(_:))
            btn.target = self
        }
        
        /// SwiftUI Inside PopOver
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 220)
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: MenuBarView(
            menuBarVM: menuBarVM
        ))
    }
    
    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
