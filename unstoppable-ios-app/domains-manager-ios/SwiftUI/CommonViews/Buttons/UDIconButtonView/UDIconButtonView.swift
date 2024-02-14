//
//  CircleIconButton.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct UDIconButtonView: View {
    
    @Environment(\.isEnabled) private var isEnabled

    let icon: Image
    let style: UDButtonIconStyle
    let callback: MainActorCallback
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback()
        } label: {
            Text("")
        }
        .buttonStyle(ControllableButtonStyle(state: .init(isEnabled: isEnabled),
                                             change: { state in
            contentView(pressed: state.pressed,
                                  isEnabled: state.isEnabled)
        }))
    }
}

// MARK: - Private methods
private extension UDIconButtonView {
    @ViewBuilder
    func contentView(pressed: Bool, isEnabled: Bool) -> some View {
        ZStack {
            currentBackgroundView(pressed: pressed,
                                  isEnabled: isEnabled)
            icon
                .resizable()
                .scaledToFit()
                .foregroundColor(isEnabled ? style.iconColor : style.iconDisabledColor)
                .frame(width: style.iconSize,
                       height: style.iconSize)
        }
    }
    
    @ViewBuilder
    func currentBackgroundView(pressed: Bool, isEnabled: Bool) -> some View {
        switch style {
        case .circle(let size, let style):
            circleBackgroundWith(pressed: pressed,
                                 isEnabled: isEnabled,
                                 size: size,
                                 style: style)
        case .rectangle(let size, let style):
            rectangleBackgroundWith(pressed: pressed,
                                    isEnabled: isEnabled,
                                    size: size,
                                    style: style)
        }
    }
    
    @ViewBuilder
    func circleBackgroundWith(pressed: Bool, 
                              isEnabled: Bool,
                              size: UDButtonIconStyle.CircleSize,
                              style: UDButtonIconStyle.CircleStyle) -> some View {
        Circle()
            .fill(isEnabled ? (pressed ? style.backgroundHighlightedColor : style.backgroundIdleColor) : style.backgroundDisabledColor)
            .frame(width: size.backgroundSize,
                   height: size.backgroundSize)
    }
    
    @ViewBuilder
    func rectangleBackgroundWith(pressed: Bool, 
                                 isEnabled: Bool,
                                 size: UDButtonIconStyle.RectangleSize,
                                 style: UDButtonIconStyle.RectangleStyle) -> some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(isEnabled ? (pressed ? style.backgroundHighlightedColor : style.backgroundIdleColor) : style.backgroundDisabledColor)
            .frame(width: size.backgroundSize,
                   height: size.backgroundSize)
            .overlay(content: {
                if isEnabled {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: 1)
                }
            })
    }
}
 
#Preview {
    ScrollView {
        VStack {
            Text("Small rectangle buttons")
                .font(.largeTitle)
            
            ForEach(UDButtonIconStyle.RectangleStyle.allCases, id: \.self) { style in
                ButtonViewer(style: .rectangle(size: .small, style: style))
            }
        }
        VStack {
            Text("Medium circle buttons")
                .font(.largeTitle)
            
            ForEach(UDButtonIconStyle.CircleStyle.allCases, id: \.self) { style in
                ButtonViewer(style: .circle(size: .medium, style: style))
            }
        }
        VStack {
            Text("Small circle buttons")
                .font(.largeTitle)
            
            ForEach(UDButtonIconStyle.CircleStyle.allCases, id: \.self) { style in
                ButtonViewer(style: .circle(size: .small, style: style))
            }
        }
      
    }
    .background(Color.backgroundDefault)
}


private struct ButtonViewer: View {
    
    let style: UDButtonIconStyle
    @State private var isBtnDisabled = false
    
    var body: some View {
        UDIconButtonView(icon: .messageCircleIcon24,
                         style: style,
                         callback: { })
        .disabled(isBtnDisabled)
        .padding()
    }
    
    func toggle() {
        isBtnDisabled.toggle()
    }
    
}

