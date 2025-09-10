//
//  HistoryManager.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import Combine
import Foundation

enum HistoryType {
    case draw
    case erase
    /// Your Undo Goes Into the History When you Undo
    case undo
}

struct HistoryItem {
    var type : HistoryType
}

final class HistoryManager: ObservableObject {
    @Published var history: [HistoryItem] = []
    
    public func add(for type: HistoryType) {
        
        let hist = HistoryItem(
            type: type
        )
        
    }
}
