//
//  WindowCoordinator.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/21/25.
//

import Foundation
import AppKit
import SwiftUI

private class WindowDelegate: NSObject, NSWindowDelegate {
    let id: String
    weak var coordinator: WindowCoordinator?
    
    init(id: String, coordinator: WindowCoordinator) {
        self.id = id
        self.coordinator = coordinator
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        coordinator?.handleWindowOpen(id: id)
    }
    
    func windowWillClose(_ notification: Notification) {
        coordinator?.handleWindowClose(id: id)
    }
}

/// Window Coordinator manages the lifecycle of multiple windows in the application.
class WindowCoordinator {
    
    private var windows : [String: NSWindow] = [:]
    
    private var onOpenAction : [String: (() -> Void)] = [:]
    private var onCloseAction : [String: (() -> Void)] = [:]
    
    private var delegates: [String: WindowDelegate] = [:]
    
    deinit {
        // Clean up all windows when the coordinator is deinitialized
        for window in windows.values {
            window.close()
        }
        windows.removeAll()
    }
    
    func showWindowWithGenie(
        id: String,
        title: String,
        content: some View,
        size: NSSize = .init(width: 600, height: 400),
        origin: CGPoint? = nil,
        side: ImageStagerSide,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        // 1) Build the window but DON'T order front yet
        showWindow(
            id: id,
            title: title,
            content: content,
            size: size,
            origin: origin,
            onOpen: onOpen,
            onClose: onClose
        )
        
        guard
            let window = windows[id],
            let contentView = window.contentView
        else { return }
        
        window.isOpaque = false
        window.backgroundColor = .clear
        
        // Ensure layer-backed now (before any ordering)
        contentView.wantsLayer = true
        contentView.layoutSubtreeIfNeeded()
        guard let layer = contentView.layer else { return }
        
        // ---- anchor setup ----
        let bounds = layer.bounds
        let pivot: CGPoint = (side == .left)
        ? CGPoint(x: 0, y: 0)
        : CGPoint(x: bounds.width, y: 0)
        
        // Helper to build a transform that scales around `pivot`
        func scaleAround(_ s: CGFloat, pivot p: CGPoint) -> CATransform3D {
            var t = CATransform3DIdentity
            // translate pivot to origin
            t = CATransform3DTranslate(t, p.x, p.y, 0)
            // apply scale
            t = CATransform3DScale(t, s, s, 1)
            // translate back
            t = CATransform3DTranslate(t, -p.x, -p.y, 0)
            return t
        }
        
        // Disable implicit actions for initial state
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Initial tiny/hidden state using pivot scaling (no anchor changes)
        let startS: CGFloat = 0.01
        layer.transform = scaleAround(startS, pivot: pivot)
        layer.opacity = 0.0
        CATransaction.commit()
        CATransaction.flush()
        
        // Show window now that it’s tiny/invisible
        window.animationBehavior = .none
        let oldHasShadow = window.hasShadow
        window.hasShadow = false
        window.makeKeyAndOrderFront(nil)
        
        // Animate next tick
        DispatchQueue.main.async {
            // Final model state first
            layer.transform = CATransform3DIdentity
            layer.opacity = 1.0
            
            // CA animations (from tiny-at-pivot -> identity)
            let t = CABasicAnimation(keyPath: "transform")
            t.fromValue = scaleAround(startS, pivot: pivot)
            t.duration = 0.5
            t.timingFunction = CAMediaTimingFunction(name: .easeOut)
            t.fillMode = .forwards
            t.isRemovedOnCompletion = false
            
            let o = CABasicAnimation(keyPath: "opacity")
            o.fromValue = 0.0
            o.duration = 0.5
            o.timingFunction = CAMediaTimingFunction(name: .easeOut)
            o.fillMode = .forwards
            o.isRemovedOnCompletion = false
            
            layer.add(t, forKey: "genieTransform")
            layer.add(o, forKey: "genieOpacity")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                window.hasShadow = oldHasShadow
            }
        }
    }
    
    func showWindow(
        id: String,
        title: String,
        content: some View,
        size: NSSize = .init(width: 600, height: 400),
        origin: CGPoint? = nil,
        onOpen: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        if let window = windows[id] {
            // Re-activate app and bring the existing window up
            NSRunningApplication.current.activate(options: [.activateAllWindows])
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
            return
        }
        
        let windowOrigin = origin ?? .zero

        let window = NSWindow(
            contentRect: NSRect(origin: windowOrigin, size: size),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Match SwiftUI window modifiers
        window.title = title
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        
        let hostingView = NSHostingView(rootView: content)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        window.contentView = hostingView
        
        /// Assign A Window Delegate
        let delegate = WindowDelegate(id: id, coordinator: self)
        window.delegate = delegate
        delegates[id] = delegate
        
        if let action = onClose {
            onCloseAction[id] = action
        }
        if let action = onOpen {
            onOpenAction[id] = action
        }
        
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        windows[id] = window
    }
    
    func closeWindow(id: String) {
        windows[id]?.close()
        /// windowWillClose will be called automatically
    }
    
    fileprivate func handleWindowOpen(id: String) {
        if let action = onOpenAction[id] {
            action()
            onOpenAction[id] = nil
        }
    }
    
    fileprivate func handleWindowClose(id: String) {
        windows[id] = nil
        delegates[id] = nil
        if let action = onCloseAction[id] {
            action()
            onCloseAction[id] = nil
        }
    }
}

extension WindowCoordinator {
    
    /// Renames an existing window's identifier and (optionally) its title.
    /// - Parameters:
    ///   - oldId: Current id used in the coordinator maps.
    ///   - newId: New id you want to use.
    ///   - newTitle: Optional new title to display in the titlebar.
    /// - Returns: true if the rename happened, false otherwise.
    @discardableResult
    public func changeWindowName(from oldId: String, to newId: String, newTitle: String? = nil) -> Bool {
        precondition(Thread.isMainThread, "Must be called on main thread")
        
        // window must exist
        guard let window = windows[oldId] else { return false }
        // don't clobber an existing entry
        guard windows[newId] == nil else { return false }
        
        // move window map
        windows.removeValue(forKey: oldId)
        windows[newId] = window
        
        // move actions if present
        if let open = onOpenAction.removeValue(forKey: oldId) {
            onOpenAction[newId] = open
        }
        if let close = onCloseAction.removeValue(forKey: oldId) {
            onCloseAction[newId] = close
        }
        
        // refresh delegate with the new id (simplest is to swap in a new one)
        let newDelegate = WindowDelegate(id: newId, coordinator: self)
        window.delegate = newDelegate
        delegates[oldId] = nil
        delegates[newId] = newDelegate
        
        // update title if requested
        if let t = newTitle {
            window.title = t
        }
        
        return true
    }
    
    /// Just change the visible title without touching ids.
    public func setTitle(for id: String, to title: String) {
        precondition(Thread.isMainThread, "Must be called on main thread")
        windows[id]?.title = title
    }
    
    public func activateWithRetry(_ tries: Int = 6) {
        guard tries > 0 else { return }
        
        // If we're already active *and* have a key window, stop retrying.
        if NSApp.isActive, NSApp.keyWindow != nil {
            return
        }
        
        bringAppFront()
        
        // Try again shortly — gives Spaces/full-screen a moment to switch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
            self?.activateWithRetry(tries - 1)
        }
    }
    
    public func bringAppFront() {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true) // harmless double-tap; one of these usually “sticks”
    }
}

