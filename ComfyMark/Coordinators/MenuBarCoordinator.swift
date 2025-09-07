//
//  MenuBarCoordinator.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import AppKit
import Combine
import SwiftUI

@MainActor
class MenuBarCoordinator: NSObject {
    
    private var statusItem: NSStatusItem? = nil
    private let popover = NSPopover()
    /// Create The MenuBarViewModel
    var menuBarVM : MenuBarViewModel? = nil

    var onSettingsTapped: (() -> Void)?
    
    private var cancellables : Set<AnyCancellable> = []

    override init() {
        super.init()
    }
    
    public func start(
        screenshotManager : ScreenshotManager,
        appSettings       : AppSettings,
        onSettingsTapped: @escaping () -> Void,
        onStartTapped: @escaping () throws -> Void,
        onStartTappedImage: @escaping (CGImage, String) -> Void
    ) {
        menuBarVM = MenuBarViewModel(
            appSettings: appSettings,
            screenshotManager: screenshotManager
        )
        guard let menuBarVM = menuBarVM else {
            print("Couldnt Initialize MenuBarViewModel Cuz of MenuBarVM Not Initialized")
            return
        }
        
        menuBarVM.onSettingsTapped = onSettingsTapped
        menuBarVM.onStartTapped = onStartTapped
        menuBarVM.onStartTappedImage = { image, projectName in
            onStartTappedImage(image, projectName)
        }
        
        let controller = NSHostingController(rootView: MenuBarView(
            menuBarVM: menuBarVM
        ))
        /// Configure The Popover With the Controller
        configurePopover(with: controller)
        /// Configure MenuBar Button
        configureMenuBarButton()
    }
    
    // MARK: - RenderTime Update
    public func updateRenderTime(_ time : TimeInterval) {
        guard let menuBarVM = menuBarVM else {
            print("Couldnt Update Render Time Cuz of MenuBarVM Not Initialized")
            return
        }
        menuBarVM.renderTimeMs = time
    }

    // MARK: - MenuBar
    private func configureMenuBarButton() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        configureMenuBarIcon()
        statusItem?.button?.imagePosition = .imageLeading
        configureMenuBarAction()
    }
    
    private func configureMenuBarAction() {
        guard let statusItem = statusItem else { return }
        guard let button = statusItem.button else { return }
        
        button.target = self
        button.action = #selector(togglePopover(_:))
    }
    
    
    /// Function will load in the menu bar icon
    /// Either our set, ComfyMarkMenuBar or default Pencil
    private func configureMenuBarIcon() {
        if let img = NSImage(named: "ComfyMarkMenuBar") {
            statusItem?.button?.image = img
        } else {
            statusItem?.button?.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Annotate")
        }
    }
    
    
    // MARK: - Popover
    
    
    /// Function to configure the popover
    private func configurePopover(with controller: NSViewController) {
        guard let menuBarVM = menuBarVM else {
            print("Couldnt Configure Popover Cuz of MenuBarVM Not Initialized")
            return
        }
        popover.contentSize = NSSize(width: menuBarVM.menuBarWidth, height: menuBarVM.menuBarHeight)
        popover.animates = false
        
        popover.contentViewController = controller
        configurePopoverSizeListener()
        
        /// Make sure we hide in the start
        popover.performClose(nil)
        print("PopOver Has been Hidden")
    }
    
    
    /// Function will change the size of the popover, as the viewmodel changes it,
    /// this was by far the best method i found
    private func configurePopoverSizeListener() {
        
        guard let menuBarVM = menuBarVM else {
            print("Couldnt Configure Popover Size Listener Cuz of MenuBarVM Not Initialized")
            return
        }

        if popover.contentViewController == nil {
            print("Pop Over Content Not Loaded yet")
            return
        }
        
        Publishers.CombineLatest(
            menuBarVM.$menuBarWidth,
            menuBarVM.$menuBarHeight
        )
        .sink { [weak self] width, height in
            guard let self = self else { return }
            let newSize = NSSize(width: width, height: height)
            
            if self.popover.isShown {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    context.timingFunction = CAMediaTimingFunction(
                        controlPoints: 0.25,
                        0.1,
                        0.25,
                        1
                    ) // Custom bezier
                    self.popover.contentSize = newSize
                }
            } else {
                /// No Need to show animation for setting size if the
                /// popover is not even showing
                self.popover.contentSize = newSize
            }
        }
        .store(in: &cancellables)
    }
    
    
    /// Function used to toggle the popover based on what it is
    /// in that current moment
    @objc private func togglePopover(_ sender: Any?) {
        
        guard statusItem != nil else {
            print("Status Item Not Configured Yet")
            return
        }
        
        if popover.contentViewController == nil {
            print("Pop Over Content Not Loaded yet")
            return
        }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }
    
    /// FORCE Function Used to show the popover
    @objc private func showPopover() {
        guard let statusItem = statusItem else {
            print("Status Item Not Configured Yet")
            return
        }
        
        guard let button = statusItem.button else {
            print("Status Item Button Not Configured Yet")
            return
        }
        
        if popover.contentViewController == nil {
            print("Pop Over Content Not Loaded yet")
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}
