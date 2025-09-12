//
//  MenuBarStart.swift
//  ComfyMark
//
//  Created by Aryan Rogye on 9/6/25.
//



import SwiftUI

private enum CaptureMode: String { case mark, crop }
private enum MenuBarViewModifierSide { case left, right }

private extension View {
    func menuBarStartStyle(
        color: AnyShapeStyle,
        isHovering: Binding<Bool>,
        accessibilityLabel: String,
        side : MenuBarViewModifierSide,
        width: CGFloat = .infinity
    ) -> some View {
        modifier(MenuBarViewModifier(
            color: color,
            isHovering: isHovering,
            accessibilityLabel: accessibilityLabel,
            width: width,
            side: side
        ))
    }
}

private struct MenuBarViewModifier: ViewModifier {
    
    var color: AnyShapeStyle
    @Binding var isHovering: Bool
    var accessibilityLabel: String
    var width: CGFloat
    var side: MenuBarViewModifierSide
    
    func body(content: Content) -> some View {
        content
            .labelStyle(.titleAndIcon)
            .imageScale(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: width, maxHeight: 18, alignment: .center)
            .padding(12)
            .background {
                UnevenRoundedRectangle(cornerRadii: cornerRadii)
                    .fill(color)
                    .opacity(isHovering ? 0.95 : 1.0)
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 0.5)
            }
            .onHover { isHovering = $0 }
            .accessibilityLabel(accessibilityLabel)
    }
    
    private var cornerRadii: RectangleCornerRadii {
        switch side {
        case .left:
            // order: topLeading, bottomLeading, bottomTrailing, topTrailing
            return .init(topLeading: 8, bottomLeading: 8, bottomTrailing: 0, topTrailing: 0)
        case .right:
            return .init(topLeading: 0, bottomLeading: 0, bottomTrailing: 8, topTrailing: 8)
        }
    }
}

struct MenuBarStart: View {
    
    @ObservedObject var menuBarVM: MenuBarViewModel
    
    /// Saving Last Capture Mode
    @AppStorage("ComfyMark.captureMode") private var modeRaw = CaptureMode.mark.rawValue
    
    private var mode: CaptureMode {
        get { CaptureMode(rawValue: modeRaw) ?? .mark }
        nonmutating set { modeRaw = newValue.rawValue }
    }
    
    @State private var isHoverLeft = false
    @State private var isHoverRight = false

    @State private var startLogo: String = "camera.viewfinder"
    @State private var captureTick: Int = 0
    @State private var showModeMenu = false
    
    private var titleText: String { mode == .mark ? "Mark" : "Crop" }
    private var iconName: String { mode == .mark ? "camera.viewfinder" : "crop" }
    
    var body: some View {
        HStack(spacing: 0) {
            let base = menuBarVM.startButtonTapped ? Color.red : Color.blue

            ComfyMarkButton {
                startButton
                    .menuBarStartStyle(
                        color: AnyShapeStyle(LinearGradient(
                            colors: [base.opacity(0.95), base.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        ,
                        isHovering: $isHoverLeft,
                        accessibilityLabel: "Mark Screen",
                        side: .left
                    )
            } action: {
                if mode == .mark {
                    // Trigger a subtle capture animation on the icon
                    captureTick &+= 1
                    menuBarVM.startTapped()
                } else if mode == .crop {
                    menuBarVM.startCropped()
                }
            }
            .help("Capture & mark the screen (Set Hotkey in Settings)")
            
            // Divider between the two
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: 0.3, height: 18)
            
            ComfyMarkButton {
                moreOptions
                    .menuBarStartStyle(
                        color: AnyShapeStyle(base),
                        isHovering: $isHoverRight,
                        accessibilityLabel: "More Options",
                        side: .right,
                        width: 25
                    )
            } action: {
                showModeMenu = !showModeMenu
            }
        }
        .animation(.spring(response: 0.18, dampingFraction: 0.9), value: isHoverLeft)
        .animation(.spring(response: 0.18, dampingFraction: 0.9), value: isHoverRight)
    }
    
    private var startButton: some View {
        HStack(spacing: 6) {
            StartMarkLogo(isHovering: isHoverLeft, symbolName: iconName, captureTick: captureTick)
            Text(titleText)
                .fontWeight(.semibold)
            Spacer()
        }

    }
    
    private var moreOptions: some View {
        HStack {
            // tiny chevron hotspot
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .opacity(0.9)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
                .popover(isPresented: $showModeMenu, arrowEdge: .top) {
                    modePicker
                }
        }
    }
    
    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            modeRow(.mark, "camera.viewfinder", "Mark")
            modeRow(.crop, "crop", "Crop")
        }
        .padding(10)
        .frame(width: 160)
    }
    private func modeRow(_ m: CaptureMode, _ icon: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
            Spacer()
            if m == mode { Image(systemName: "checkmark") }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            mode = m
            showModeMenu = false
        }
        .padding(6)
        .background(m == mode ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.clear))
        .cornerRadius(6)
    }
}
