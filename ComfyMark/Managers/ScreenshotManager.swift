//
//  ScreenshotManager.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/5/25.
//

import AppKit
import Foundation
import Combine
import UniformTypeIdentifiers

struct ScreenshotThumbnailInfo: Hashable, Identifiable {
    var id: URL { url }
    var url: URL
    var thumbnail: NSImage
    
    static func ==(l: Self, r: Self) -> Bool { l.url == r.url }
    func hash(into h: inout Hasher) { h.combine(url) }
}

@MainActor
final class ScreenshotManager: ObservableObject {
    
    @Published var screenshotHistory: [ScreenshotThumbnailInfo] = []

    let appURL: URL?
    
    init(saving: SavingProviding) {
        appURL = try? saving.comfyAppSupportURL()
        
        Task {
            await self.loadHistoryInBackground()
            objectWillChange.send()
        }
    }
    
    public func loadHistoryInBackground() async {
        for await screenshot in loadScreenshotHistory() {
            // Each time a screenshot loads, add it to the array
            await MainActor.run {
                if !screenshotHistory.contains(where: { $0.url == screenshot.url }) {
                    screenshotHistory.append(screenshot)
                }
            }
        }
    }
    
    
    public func loadScreenshotHistory() -> AsyncStream<ScreenshotThumbnailInfo> {
        guard let appURL else { return AsyncStream<ScreenshotThumbnailInfo> { _ in } }
        
        let urls = getContentsOfDirectory(url: appURL)
        
        return AsyncStream { continuation in
            Task {
                for url in urls {
                    if isImageFile(url) {
                        
                        if let fullImage = NSImage(contentsOf: url) {
                            
                            /// Get Thumbnail
                            let thumbnail = await createThumbnail(
                                from: fullImage,
                                size: NSSize(width: 40, height: 40)
                            )
                            
                            continuation.yield(
                                ScreenshotThumbnailInfo(
                                    url: url,
                                    thumbnail: thumbnail
                                )
                            )
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
    
    private func isImageFile(_ url: URL) -> Bool {
        let imageExts = ["png", "jpg", "jpeg", "gif", "heic"]
        return imageExts.contains(url.pathExtension.lowercased())
    }
    
    private func getContentsOfDirectory(url: URL) -> [URL] {
        do {
            // Ensure the URL represents a directory
            guard url.isFileURL && url.hasDirectoryPath else {
                print("The provided URL does not represent a directory.")
                return []
            }
            
            // Use FileManager to get the contents of the directory
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil, // Include desired properties, or nil for none
                options: .skipsHiddenFiles // Adjust options as needed (e.g., .skipsPackageDescendants)
            )
            return directoryContents
        } catch {
            print("Error getting directory contents: \(error)")
            return []
        }
    }
    
    private func createThumbnail(from image: NSImage, size: CGSize) async -> NSImage {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        
        // Calculate aspect ratio to maintain proportions
        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height
        
        var drawRect: NSRect
        if aspectRatio > 1 {
            // Landscape
            let height = size.height
            let width = height * aspectRatio
            drawRect = NSRect(x: -(width - size.width) / 2, y: 0, width: width, height: height)
        } else {
            // Portrait or square
            let width = size.width
            let height = width / aspectRatio
            drawRect = NSRect(x: 0, y: -(height - size.height) / 2, width: width, height: height)
        }
        
        image.draw(in: drawRect)
        thumbnail.unlockFocus()
        
        print("Created thumbnail - Original: \(imageSize), Thumbnail: \(size)")
        
        return thumbnail
    }
}
