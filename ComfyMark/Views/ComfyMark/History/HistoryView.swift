//
//  HistoryView.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/9/25.
//

import SwiftUI

struct HistoryView: View {
    
    @ObservedObject var comfyMarkVM : ComfyMarkViewModel
    var geo: GeometryProxy
    
    var body: some View {
        ViewSidebar(geo) {
            Text("History View")
        }
    }
}
