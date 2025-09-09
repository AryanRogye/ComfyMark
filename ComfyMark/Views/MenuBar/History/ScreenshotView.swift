//
//  ScreenshotHistoryView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct MenuBarScreenshotView: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    @State private var shouldShow = false
    
    @State private var shouldShowReload = false
    @State private var secondClickCountClicked = false
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    usersScreenshots
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                    bottomText
                        .padding(.bottom, 4)
                    
                }
            }
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
                    if e.keyCode == 51, e.modifierFlags.contains(.command) {
                        menuBarVM.handleMultipleDeleteShortcut()
                        return nil
                    }
                    return e
                }
            }
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            withAnimation(.snappy(duration: 0.25)) { shouldShow = true }
        }
        .onDisappear {
            withAnimation(.snappy(duration: 0.25)) { shouldShow = false }
        }
    }
    
    func fileDate(_ url: URL) -> Date {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate]) as? Date ?? .distantPast
    }
    
    // MARK: - ScrollView
    private var usersScreenshots: some View {
        ForEach(Array(
            /// Sort By Creation
            menuBarVM.screenshotManager.screenshotHistory
                .sorted { fileDate($0.url) > fileDate($1.url) }
                .enumerated()),
                id: \.element.id
        ) { i, history in
            HistoryImageView(
                menuBarVM: menuBarVM, index: i,
                history: history
            )
            .opacity(shouldShow ? 1 : 0)
            .scaleEffect(shouldShow ? 1 : 0.98)
            .animation(.snappy(duration: 0.22).delay(0.012 * Double(i)), value: shouldShow)
            .contentShape(Rectangle())
            .onDrag {
                let item = NSItemProvider()
                
                // 1) Offer the file URL itself
                item.registerObject(history.url as NSURL, visibility: .all) // provides public.file-url
                
                // 2) Also offer image data (PNG). Drop targets that want an image will use this.
                item.registerFileRepresentation(
                    forTypeIdentifier: UTType.png.identifier,
                    fileOptions: [],
                    visibility: .all
                ) { completion in
                    // If your screenshots are PNGs already, you can just pass the same file.
                    // Otherwise convert to a temp PNG and pass that URL.
                    completion(history.url, /* isStale */ false, nil)
                    return nil
                }
                
                item.suggestedName = history.url.deletingPathExtension().lastPathComponent
                return item
            }
            
            .onTapGesture {
                if NSEvent.modifierFlags.contains(.command) || NSEvent.modifierFlags.contains(.shift) {
                    
                    /// If Already a set value, keep it in
                    if let sel = menuBarVM.selectedHistoryIndex {
                        menuBarVM.selectedHistoryIndexs.insert(sel)
                        menuBarVM.selectedHistoryIndex = nil
                    }
                    
                    menuBarVM.selectedHistoryIndexs.insert(i)
                    menuBarVM.showMoreOptions = false
                    
                } else {
                    
                    if menuBarVM.selectedHistoryIndex == i && !secondClickCountClicked {
                        /// Double Clicked
                        secondClickCountClicked = true
                        menuBarVM.showMoreOptions = true
                    } else {
                        menuBarVM.selectedHistoryIndex = i
                        secondClickCountClicked = false
                        menuBarVM.showMoreOptions = false
                    }
                    
                    menuBarVM.selectedHistoryIndexs.removeAll()
                }
            }
            
            if menuBarVM.showMoreOptions && menuBarVM.selectedHistoryIndex == i {
                MenuBarHistoryMoreOptions(
                    menuBarVM: menuBarVM,
                    index: i,
                    history: history
                )
            }
        }
    }
    
    // MARK: - Bottom View
    private var bottomText: some View {
        VStack(spacing: 1) {
            
            Text("No More Screenshots")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 6) {
                Button("Refresh") {
                    Task {
                        shouldShowReload = true
                        await menuBarVM.screenshotManager.loadHistoryInBackground()
                        shouldShowReload = false
                    }
                }
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
                
                // reserve 12x12 space so layout doesn’t shift
                if shouldShowReload {
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: 12, height: 12)
                } else {
                    Color.clear.frame(width: 12, height: 12)
                }
            }
            
            Button(action: {
                menuBarVM.screenshotManager.openScreenshotFolder()
            }) {
                Text("Open Screenshot Folder")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

        }
    }
}

// MARK: - History Image View
struct HistoryImageView: View {
    
    var menuBarVM: MenuBarViewModel
    var index: Int
    
    var history: ScreenshotThumbnailInfo
    var resourceValues : URLResourceValues?
    
    // Format into "x days ago"
    let formatter = RelativeDateTimeFormatter()
    
    init(
        menuBarVM: MenuBarViewModel,
        index: Int,
        history: ScreenshotThumbnailInfo
    ) {
        self.menuBarVM = menuBarVM
        self.index = index
        
        self.history = history
        resourceValues = try? history.url.resourceValues(forKeys: [.contentAccessDateKey,
                                                                   .contentModificationDateKey,
                                                                   .creationDateKey])
        
        formatter.unitsStyle = .full // can be .abbreviated or .short too
    }
    
    var body: some View {
        HStack(alignment: .center) {
            /// Already should be 40x40 in NSImage but still its ok
            Image(nsImage: history.thumbnail)
                .resizable()
                .interpolation(.medium)
                .frame(width: 40, height: 40)
                .clipShape (
                    RoundedRectangle(cornerRadius: 12)
                )
            
            VStack(alignment: .leading) {
                thumbnailName
                thumbnailDate()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .padding([.horizontal, .vertical], 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    menuBarVM.selectedHistoryIndex == index || menuBarVM.selectedHistoryIndexs.contains(index)
                    ? Color.blue
                    : .clear
                )
        }
    }
    
    private var thumbnailName: some View {
        Text(history.url.lastPathComponent)
            .font(.system(size: 12, weight: .regular, design: .default))
            .foregroundStyle(
                menuBarVM.selectedHistoryIndex == index || menuBarVM.selectedHistoryIndexs.contains(index)
                ? .white
                : .primary
            )
            .lineLimit(2)
            .minimumScaleFactor(0.5)
    }
    
    
    
    @ViewBuilder
    private func thumbnailDate() -> some View {
        if let resourceValues = resourceValues,
           let created = resourceValues.creationDate {
            
            let relativeString = formatter.localizedString(for: created, relativeTo: Date())
            
            Text(relativeString)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundStyle(
                    menuBarVM.selectedHistoryIndex == index || menuBarVM.selectedHistoryIndexs.contains(index)
                    ? .white
                    : .primary
                )
        }
    }
}
