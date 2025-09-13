//
//  AppSettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import Combine
import AppKit
import Foundation
import ServiceManagement

@MainActor
class AppSettings: ObservableObject {
    enum Keys {
        static let showDockIcon                  = "showDockIcon"
        static let menuBarPowerButtonSide        = "menuBarPowerButtonSide"
        static let screenshotSide                = "screenshotSide"
        static let allowNativeScreenshotBehavior = "allowNativeScreenshotBehavior"
    }
    
    /// Defaults
    /// I do this because in init we can inject different settings
    /// and its nicer to test with
    private var defaults: UserDefaults

    @Published var isSettingsWindowOpen = false
    
    @Published var showDockIcon : Bool {
        didSet {
            defaults.set(showDockIcon, forKey: Keys.showDockIcon)
        }
    }
    
    @Published var menuBarPowerButtonSide: MenuBarPowerButtonSide {
        didSet {
            defaults.set(menuBarPowerButtonSide.rawValue, forKey: Keys.menuBarPowerButtonSide)
        }
    }
    
    @Published var screenshotSide: ImageStagerSide {
        didSet {
            defaults.set(screenshotSide.rawValue, forKey: Keys.screenshotSide)
        }
    }
    
    @Published var allowNativeScreenshotBehavior: Bool {
        didSet {
            defaults.set(allowNativeScreenshotBehavior, forKey: Keys.allowNativeScreenshotBehavior)
        }
    }
    
    
    /// We Dont Save this cuz we read this value from the system
    @Published var launchAtLogin: Bool
    
    /// Flag to know if the App Icon is showing or not
    private var isShowingAppIcon: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Register a default so the first read doesn't cause a write
        AppSettings.registerDefaults(in: defaults)
        
        self.launchAtLogin = (SMAppService.mainApp.status == .enabled)
        
        self.showDockIcon = defaults.bool(forKey: Keys.showDockIcon)
        
        /// Init menuBarPowerButtonSide
        let side : String = defaults.string(forKey: Keys.menuBarPowerButtonSide) ?? "right"
        self.menuBarPowerButtonSide = MenuBarPowerButtonSide(rawValue: side) ?? .right
        
        /// Init ScreenshotSide
        let screenshotSide = defaults.string(forKey: Keys.screenshotSide) ?? ImageStagerSide.right.rawValue
        self.screenshotSide = ImageStagerSide(rawValue: screenshotSide) ?? .right
        
        /// Init Allow Native Screenshot Behavior
        self.allowNativeScreenshotBehavior = defaults.bool(forKey: Keys.allowNativeScreenshotBehavior)
        
        // MARK: - Binding Dock Icon
        $showDockIcon
            .sink { [weak self] show in
                guard let self = self else { return }
                if show {
                    /// at anytime if showDockIcon is called, we can just show the App Icon
                    self.showAppIcon()

                } else {
                    /// if the settings page is open when we toggle this off, which most likely we will
                    /// exit early because the settingsWindowOpen bind handles that
                    if self.isSettingsWindowOpen { return }
                    /// I dont think we would ever get here but if we do, just hide the app icon
                    self.hideAppIcon()
                }
            }
            .store(in: &cancellables)
        
        // MARK: - Bind Settings Window Open
        $isSettingsWindowOpen
            .sink { [weak self] isOpen in
                guard let self = self else { return }
                if isOpen {
                    /// By default if the settings page is open we always show the App Icon,/
                    self.showAppIcon()
                } else {
                    /// If the user decides that they want to show the dock icon we just return early if self.showDockIcon { return }
                    /// if they have showDockIcon toggled off then we show the hide the dock icon when closing
                    self.hideAppIcon()
                }
            }
            .store(in: &cancellables)
        
        // MARK: - Binding Launch At Login
        $launchAtLogin
            .sink { [weak self] launchAtLogin in
                guard let self = self else { return }
                /// If We Set Launch At Login
                if launchAtLogin {
                    if SMAppService.mainApp.status == .enabled { return }
                    do {
                        try SMAppService.mainApp.register()
                    } catch {
                        print("Couldnt Register ComfyTab to Launch At Login \(error.localizedDescription)")
                        /// Toggle it Off
                        self.launchAtLogin = false
                    }
                }
                /// If Launch At Logic is Turned off
                else {
                    /// ONLY go through if the status is enabled
                    if SMAppService.mainApp.status != .enabled { return }
                    do {
                        try SMAppService.mainApp.unregister()
                    } catch {
                        print("Couldnt Turn Off Launch At Logic for ComfyTab \(error.localizedDescription)")
                        self.launchAtLogin = true
                    }
                }
            }
            .store(in: &cancellables)

    }
}

extension AppSettings {
    private func showAppIcon() {
        if !isShowingAppIcon {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            isShowingAppIcon  = true
        }
    }
    
    private func hideAppIcon() {
        if isShowingAppIcon {
            /// makes sure we don’t hide the icon if the user flipped something back during that second.
            /// I use a Second cuz its a bit safer
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self,
                      !self.isSettingsWindowOpen,
                      !self.showDockIcon
                else {
                    return
                }
                
                NSApp.setActivationPolicy(.accessory)
                isShowingAppIcon = false
            }
        }
    }
}

// MARK: - Default Registering
extension AppSettings {
    public static func registerDefaults(in defaults: UserDefaults = .standard) {
        registerMenuBarPowerButtonSide(defaults)
        registerShowDockIcon(defaults)
        registerScreenshotSide(defaults)
        registerAllowNativeScreenshotBehavior(defaults)
    }
    
    private static func registerMenuBarPowerButtonSide(_ defaults: UserDefaults) {
        defaults.register(defaults: [Keys.menuBarPowerButtonSide: MenuBarPowerButtonSide.right.rawValue])
    }
    
    private static func registerShowDockIcon(_ defaults: UserDefaults) {
        defaults.register(defaults: [Keys.showDockIcon: false])
    }
    
    private static func registerScreenshotSide(_ defaults: UserDefaults) {
        defaults.register(defaults: [Keys.screenshotSide: ImageStagerSide.right.rawValue])
    }
    
    private static func registerAllowNativeScreenshotBehavior(_ defaults: UserDefaults) {
        defaults.register(defaults: [Keys.allowNativeScreenshotBehavior: true])
    }
}
