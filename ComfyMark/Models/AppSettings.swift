//
//  AppSettings.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import Combine
import Foundation

class AppSettings: ObservableObject {
    enum Keys {
        static let showDockIcon             = "showDockIcon"
    }
    
    /// Defaults
    /// I do this because in init we can inject different settings
    /// and its nicer to test with
    private var defaults: UserDefaults

    
    @Published var showDockIcon : Bool {
        didSet {
            defaults.set(showDockIcon, forKey: Keys.showDockIcon)
        }
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Register a default so the first read doesn't cause a write
        AppSettings.registerDefaults(in: defaults)
        
        self.showDockIcon = defaults.bool(forKey: Keys.showDockIcon)
    }
}

extension AppSettings {
    public static func registerDefaults(in defaults: UserDefaults = .standard) {
        registerShowDockIcon(defaults)
    }
    private static func registerShowDockIcon(_ defaults: UserDefaults) {
        defaults.register(defaults: [Keys.showDockIcon: false])
    }
}
