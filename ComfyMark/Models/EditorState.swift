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
    case undo  = "Undo"
    case redo  = "Redo"
    case brush_radius = "Brush Radius"
    
    var icon: String {
        switch self {
        case .move:     return "hand.draw"
        case .draw:     return "pencil.tip"
        case .erase:    return "eraser"
        case .undo:     return "arrow.counterclockwise.circle"
        case .redo:     return "arrow.clockwise.circle"
        case .brush_radius : return "circle"
        }
    }
    
    public static var nonOneClickStates: [EditorState] {
        return [.undo, .redo, .brush_radius]
    }
}

