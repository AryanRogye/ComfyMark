//
//  ImageStageViewModel.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/12/25.
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

public final class ImageStageViewModel: ObservableObject {
    
    @Published public var image: CGImage?
    
    @Published var isHovering = false
    @Published var showTapGesture = false
    @Published var hoverTask: Task<Void, Never>?

    var onExit: (() -> Void)?
    var onImageTapped: (() -> Void)?
    
    public func exitTapped() {
        onExit?()
        isHovering = false
        showTapGesture = false
        hoverTask?.cancel()
    }
    
    public func imageTapped() {
        onImageTapped?()
        exitTapped()
    }
    
    init() {
    }
    
    
    public func handleHover(_ value: Bool) {
        hoverTask?.cancel()
        
        if !value {
            showTapGesture = false
        } else {
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled {
                    showTapGesture = true
                }
            }
        }
    }

    public func onDrag() -> NSItemProvider {
        guard let img = image else { return NSItemProvider() }
        let provider = NSItemProvider()
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".png"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        if let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, img, nil)
            if CGImageDestinationFinalize(destination) {
                provider.registerObject(fileURL as NSURL, visibility: .all)
                provider.suggestedName = fileURL.deletingPathExtension().lastPathComponent
            }
        }
        return provider
    }
}
