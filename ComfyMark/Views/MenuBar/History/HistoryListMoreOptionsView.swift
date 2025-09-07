//
//  HistoryListMoreOptionsView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/7/25.
//

import SwiftUI


/// used to show more options for whatever is selected, in teh history view
struct HistoryListMoreOptionsView: View {
    
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
    @State private var erasePressed = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(HistoryListViewOptions.allCases, id: \.self) { option in
                
                if erasePressed && option == .close || !erasePressed {
                    
                    Button(action: {
                        
                        if option == .open {
                            menuBarVM.onStartTappedOn(history)
                        }
                        
                        if option == .erase {
                            erasePressed = true
                        }
                        
                    }) {
                        option.view
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: "Buttons-\(option.rawValue)", in: ns)
                }
                
                
                if erasePressed {
                    
                    Button("Delete?") {
                        
                    }
                    .matchedGeometryEffect(id: "Buttons-Are You Sure", in: ns)
                    
                    
                    Button("Nah?") {
                        erasePressed = false
                    }
                    .matchedGeometryEffect(id: "Buttons-Nah", in: ns)
                }
                

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
}
