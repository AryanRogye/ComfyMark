//
//  HistoryManager.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import Combine
import Foundation

final class HistoryManager: ObservableObject {
    
    @Published private(set) var items: [HistoryItem] = []  // full timeline/log
    
    @Published private(set) var undoStack: [HistoryItem] = []
    @Published private(set) var redoStack: [HistoryItem] = []
    
    func canUndo() -> Bool { !undoStack.isEmpty }
    func canRedo() -> Bool { !redoStack.isEmpty }
    
    /// Use when the UI change is already applied (e.g. live drawing).
    func commitApplied(
        operation: any Undoable,
    ) {
        let item = HistoryItem(
            operation: operation
        )
        items.append(item)
        undoStack.append(item)
        redoStack.removeAll()
    }
    
    /// Undo the Stack
    func undo() {
        guard let item = undoStack.popLast() else { return }
        
        item.operation.revert()
        
        redoStack.append(item)
        
        items.append(HistoryItem(operation: item.operation))
    }
    
    func redo() {
        guard let item = redoStack.popLast() else { return }
        item.operation.perform()
        undoStack.append(item)
        
        items.append(HistoryItem(operation: item.operation))
    }
}
