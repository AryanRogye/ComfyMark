//
//  Undoable.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/10/25.
//

protocol Undoable {
    var  type : HistoryType { get }
    func perform()
    func revert()
}
