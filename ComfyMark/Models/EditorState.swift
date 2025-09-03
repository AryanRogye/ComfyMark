//
//  EditorState.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/3/25.
//

enum EditorState: String, CaseIterable {
    case move = "Move"
    case draw = "Draw"
    case erase = "Erase"
    
    var icon: String {
        switch self {
        case .move:     return "hand.draw"
        case .draw:     return "pencil.tip"
        case .erase:    return "eraser"
        }
    }
}
