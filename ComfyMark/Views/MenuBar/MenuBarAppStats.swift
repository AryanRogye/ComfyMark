//
//  MenuBarAppStats.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//

import SwiftUI

struct MenuBarAppStats: View {
    
    @ObservedObject var menuBarVM : MenuBarViewModel
    
    let textFont   : CGFloat = 12.0
    let numberFont : CGFloat = 13.0

    var body: some View {
        HStack {
            MenuBarStatsContainer {
                MenuBarRenderTime(
                    menuBarVM: menuBarVM,
                    textFont: textFont,
                    numberFont: numberFont
                )
            }
            
            MenuBarStatsContainer {
                MenuBarScreenshotNumber(
                    screenshotManager: menuBarVM.screenshotManager,
                    textFont: textFont,
                    numberFont: numberFont
                )
            }
        }
    }
}

struct MenuBarScreenshotNumber: View {
    
    @ObservedObject var screenshotManager : ScreenshotManager
    
    let textFont: CGFloat
    let numberFont: CGFloat
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Screenshots")
                .font(.system(size: textFont, weight: .regular, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text("\(screenshotManager.screenshotHistory.count)")
                .font(.system(size: numberFont, weight: .regular, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

struct MenuBarRenderTime: View {
    @ObservedObject var menuBarVM : MenuBarViewModel
    let textFont: CGFloat
    let numberFont: CGFloat

    var body: some View {
        VStack(alignment: .leading) {
            Text("Last Render")
                .font(.system(size: textFont, weight: .regular, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            HStack(spacing: 0) {
                AnimatedCounterText(value: menuBarVM.renderTimeMs,
                                     numberFont: numberFont)
                    .animation(.easeOut(duration: 0.35), value: menuBarVM.renderTimeMs)
                Text("Ms")
                    .font(.system(size: numberFont+1, weight: .regular, design: .monospaced))
                    .padding(.leading, 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

// MARK: - Animated Counter Text

/// A lightweight animating number for smooth up/down counting when the value changes.
private struct AnimatedCounterText: View, Animatable {
    var value: Double
    let numberFont: CGFloat

    // Bridge the value into SwiftUI's interpolation system.
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(value, specifier: "%.2f")")
            .font(.system(size: numberFont, weight: .regular, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
