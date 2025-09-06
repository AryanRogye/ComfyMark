//
//  Bundle.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/5/25.
//
import Foundation

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
    var versionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }
}
