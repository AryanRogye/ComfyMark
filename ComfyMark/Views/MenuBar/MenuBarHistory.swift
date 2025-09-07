//
//  MenuBarHistory.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/2/25.
//

import SwiftUI

struct MenuBarHistory: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    var body: some View {
        VStack {
            MenuBarHistoryButton(menuBarVM: menuBarVM)
            if menuBarVM.isShowingHistory {
                ScreenshotHistoryView(menuBarVM: menuBarVM)
            }
        }
    }
}

struct ScreenshotHistoryView: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    @State private var shouldShow = false
    @State private var shouldShowReload = false
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(Array(menuBarVM.screenshotManager.screenshotHistory.enumerated()), id: \.element.id) { i, history in
                        HistoryImageView(history: history)
                            .opacity(shouldShow ? 1 : 0)
                            .scaleEffect(shouldShow ? 1 : 0.98)
                            .animation(.snappy(duration: 0.22).delay(0.012 * Double(i)), value: shouldShow)
                            .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    
                    bottomText
                        .padding(.bottom, 4)
                    
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
        }
    }
}


struct HistoryImageView: View {
    
    var history: ScreenshotThumbnailInfo
    var resourceValues : URLResourceValues?
    
    // Format into "x days ago"
    let formatter = RelativeDateTimeFormatter()

    init(history: ScreenshotThumbnailInfo) {
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
        }
        .frame(height: 50) // stable row height
        .padding(.horizontal, 2)
    }
    
    private var thumbnailName: some View {
        Text(history.url.lastPathComponent)
            .font(.system(size: 12, weight: .regular, design: .default))
    }
    
    
    
    @ViewBuilder
    private func thumbnailDate() -> some View {
        if let resourceValues = resourceValues,
           let created = resourceValues.creationDate {
            
            let relativeString = formatter.localizedString(for: created, relativeTo: Date())
            
            Text(relativeString)
                .font(.system(size: 12, weight: .regular, design: .default))
        }
    }
}

struct MenuBarHistoryButton: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    var body: some View {
        MenuBarMaterialButton {
            HStack {
                Label("View History", systemImage: "clock")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.compact.down")
                    .resizable()
                    .frame(width: 11, height: 7)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(menuBarVM.isShowingHistory ? 180 : 0))
                    .animation(.spring(response: 0.25, dampingFraction: 0.9),
                               value: menuBarVM.isShowingHistory)
            }
        } action: {
            menuBarVM.isShowingHistory.toggle()
        }
    }
}
