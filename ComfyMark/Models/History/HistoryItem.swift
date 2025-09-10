//
//  HistoryItem.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

import Foundation

struct HistoryItem: Identifiable, Equatable {
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        return (
            lhs.id == rhs.id &&
            lhs.operation.type == rhs.operation.type &&
            lhs.timestamp == rhs.timestamp
        )
    }
    
    let id = UUID()
    let operation : any Undoable
    let timestamp = Date()
}
