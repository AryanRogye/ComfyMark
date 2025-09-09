//
//  HistoryListMoreOptionsView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/7/25.
//

import SwiftUI


/// used to show more options for whatever is selected, in teh history view
struct MenuBarHistoryMoreOptions: View {
    
    enum HistoryListViewOptions: String, CaseIterable {
        case open = "Open"
        case erase = "Erase"
        case close = "Close"
        
        var icon: String {
            switch self {
            case .open:  return "arrow.up.right.square"
            case .erase: return "trash"
            case .close: return "xmark.circle"
            }
        }
        
        @ViewBuilder
        var view: some View {
            HStack {
                Image(systemName: self.icon)
                    .resizable()
                    .frame(width: 9, height: 9)
                
                Text(self.rawValue)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background (
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
            .padding(.horizontal, 4)
        }
    }
    
    @ObservedObject var menuBarVM: MenuBarViewModel
    var index: Int
    var history: ScreenshotThumbnailInfo
    @Namespace var ns
    
    @State private var isDeleting = false
    
    var body: some View {
        HStack(spacing: 0) {
            
            ForEach(HistoryListViewOptions.allCases, id: \.self) { option in
                
                if !menuBarVM.historyErasePressed {
                    
                    Button(action: {
                        
                        if option == .open {
                            menuBarVM.onStartTappedOn(history)
                        }
                        
                        if option == .erase {
                            menuBarVM.historyErasePressed = true
                        }
                        
                        if option == .close {
                            menuBarVM.selectedHistoryIndex = nil
                        }
                        
                    }) {
                        option.view
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "Buttons-\(option.rawValue)", in: ns)
                }
            }
            
            if menuBarVM.historyErasePressed {
                eraseOptions
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue)
        }
        .foregroundStyle(.white)
    }
    
    
    // MARK: - Erase Options
    private var eraseOptions: some View {
        HStack {
            Text("Delete Screenshot?")
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            Button("No") {
                menuBarVM.historyErasePressed = false
            }
            .matchedGeometryEffect(id: "Buttons-Nah", in: ns)
            .padding(4)
            .padding(.horizontal, 6)
            .background (
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
            .buttonStyle(.plain)
            
            Button(action: {
                isDeleting = true
                menuBarVM.removeURL(history.url)
                
                Task {
                    await menuBarVM.screenshotManager.loadHistoryInBackground()
                    menuBarVM.selectedHistoryIndex = nil
                    menuBarVM.historyErasePressed = false
                    isDeleting = false
                }
            }) {
                HStack(spacing: 6) {
                    if isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                            .scaleEffect(0.8)
                    }
                    Text(isDeleting ? "Deleting..." : "Yes")
                }
                .frame(minWidth: 40)
            }
            .matchedGeometryEffect(id: "Buttons-Are You Sure", in: ns)
            .padding(4)
            .background (
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
            .buttonStyle(.plain)
            .disabled(isDeleting)
            
        }
    }    
}
