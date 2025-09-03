//
//  GeneralViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

import Combine

class GeneralViewModel: ObservableObject {
    var appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
}
