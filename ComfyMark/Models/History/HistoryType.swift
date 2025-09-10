//
//  HistoryType.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

enum HistoryType {
    case draw
    case erase
    /// Your Undo Goes Into the History When you Undo
    case undo
    
    var label: String {
        switch self {
        case .draw:     "Draw"
        case .erase:    "Erase"
        case .undo:     "Undo"
        }
    }
}
