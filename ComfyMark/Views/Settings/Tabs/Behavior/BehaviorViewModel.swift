//
//  BehaviorViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import Combine
import SwiftUI

class BehaviorViewModel: ObservableObject {
    
    var appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
}
