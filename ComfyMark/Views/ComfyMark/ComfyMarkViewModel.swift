//
//  ComfyMarkViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 8/31/25.
//

import Combine
import AppKit

@MainActor
class ComfyMarkViewModel: ObservableObject {
    @Published var image: CGImage
    
    init(image: CGImage) {
        self.image = image
    }
}
