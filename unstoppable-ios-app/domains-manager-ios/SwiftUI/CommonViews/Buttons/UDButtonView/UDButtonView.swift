//
//  UDButtonView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 20.11.2023.
//

import SwiftUI

struct UDButtonView: View {
    
    @Environment(\.isEnabled) var isEnabled

    let text: String
    var subtext: String?
    var icon: Image? = nil
    var iconAlignment: UDButtonImage.Alignment = .left
    let style: UDButtonStyle
    var isLoading = false
    var isSuccess = false
    let callback: MainActorCallback
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback()
        } label: {
            Text("")
        }
        .buttonStyle(ControllableButtonStyle(state: .init(isEnabled: isEnabled,
                                                          isLoading: self.isLoading,
                                                          isSuccess: self.isSuccess),
                                             change: { state in
            ZStack {
                HStack(spacing: style.titleImagePadding) {
                    if state.isLoading {
                        ProgressView()
                            .tint(style.textColor)
                            .scaleEffect(0.85)
                    }
                    leftIcon()
                    VStack(spacing: 0) {
                        Text(text)
                            .font(style.font)
                            .lineLimit(1)
                            .frame(height: 24)
                        if style.isSupportingSubhead,
                           let subtext {
                            Text(subtext)
                                .font(.currentFont(size: 11, weight: .semibold))
                                .foregroundStyle(Color.foregroundOnEmphasisOpacity)
                                .lineLimit(1)
                                .frame(height: 16)
                        }
                    }
                    rightIcon()
                }
                .adjustContentSizeForStyle(style)
            }
            .foregroundColor(textColorForCurrentState(buttonStateFor(state: state)))
            .background(backgroundColorForCurrentState(buttonStateFor(state: state)))
            .cornerRadius(style.cornerRadius)
        }))
    }
}

// MARK: - Private methods
private extension UDButtonView {
    func buttonStateFor(state: ControllableButtonState) -> ButtonState {
        ButtonState.stateFor(pressed: state.pressed,
                             isEnabled: state.isEnabled,
                             isSuccess: state.isSuccess)
    }
    
    func textColorForCurrentState(_ state: ButtonState) -> Color {
        switch state {
        case .idle:
            return style.textColor
        case .highlighted:
            return style.textHighlightedColor
        case .disabled:
            return style.textDisabledColor
        case .success:
            return style.textSuccessColor
        }
    }
    
    func backgroundColorForCurrentState(_ state: ButtonState) -> Color {
        switch state {
        case .idle:
            return style.backgroundIdleColor
        case .highlighted:
            return style.backgroundHighlightedColor
        case .disabled:
            return style.backgroundDisabledColor
        case .success:
            return style.backgroundSuccessColor
        }
    }
    
    @ViewBuilder
    func iconView(for icon: Image) -> some View {
        icon
            .resizable()
            .scaledToFit()
            .frame(width: style.iconSize,
                   height: style.iconSize)
    }
    
    @ViewBuilder
    func leftIcon() -> some View {
        if let icon,
           case .left = iconAlignment {
            iconView(for: icon)
        }
    }
    
    @ViewBuilder
    func rightIcon() -> some View {
        if let icon,
           case .right = iconAlignment {
            iconView(for: icon)
        }
    }
}

// MARK: - Private methods
fileprivate extension UDButtonView {
    struct AutoAdjustSizeModifier: ViewModifier {
        let style: UDButtonStyle
        
        func body(content: Content) -> some View {
            switch style {
            case .large:
                content
                    .sideInsets(24)
                    .frame(maxWidth: .infinity)
                    .frame(height: style.height)
            case .medium, .small, .verySmall:
                content
                    .sideInsets(12)
                    .frame(height: style.height)
            }
        }
    }
     
    enum ButtonState {
        case idle, highlighted, disabled, success
        
        static func stateFor(pressed: Bool, isEnabled: Bool, isSuccess: Bool) -> ButtonState {
            if isSuccess {
                return .success
            } else if !isEnabled {
                return .disabled
            } else if pressed {
                return .highlighted
            }
            return .idle
        }
    }
}

fileprivate extension View {
    func adjustContentSizeForStyle(_ style: UDButtonStyle) -> some View {
        modifier(UDButtonView.AutoAdjustSizeModifier(style: style))
    }
}

#Preview {
    ScrollView {
        VStack {
            Text("Stack view alignment")
                .font(.largeTitle)
            HStack {
                ButtonViewer(style: .large(.raisedPrimary))
//                ButtonViewer(style: .large(.raisedPrimary))
                ButtonViewer(style: .medium(.ghostPrimary))
            }
        }
        VStack {
            Text("Large buttons")
                .font(.largeTitle)
            ForEach(UDButtonStyle.LargeStyle.allCases, id: \.self) { largeStyle in
                ButtonViewer(style: .large(largeStyle))
            }
        }
        VStack {
            Text("Medium buttons")
                .font(.largeTitle)
            ForEach(UDButtonStyle.MediumStyle.allCases, id: \.self) { mediumStyle in
                ButtonViewer(style: .medium(mediumStyle))
            }
        }
        VStack {
            Text("Small buttons")
                .font(.largeTitle)
            ForEach(UDButtonStyle.SmallStyle.allCases, id: \.self) { smallStyle in
                ButtonViewer(style: .small(smallStyle))
            }
        }
        VStack {
            Text("Very small buttons")
                .font(.largeTitle)
            ForEach(UDButtonStyle.VerySmallStyle.allCases, id: \.self) { verySmallStyle in
                ButtonViewer(style: .verySmall(verySmallStyle))
            }
        }
    }
    .padding()
    .background(Color.backgroundDefault)
}


private struct ButtonViewer: View {
    
    let style: UDButtonStyle
    @State private var isBtnDisabled = false
    @State private var isLoading = false
    @State private var isSuccess = false

    var body: some View {
        UDButtonView(text: style.name,
                     subtext: nil,
                     icon: nil, //.messageCircleIcon24,
                     iconAlignment: .left,
                     style: style,
                     isLoading: isLoading,
                     isSuccess: isSuccess,
                     callback: {
            isLoading.toggle()
//            isSuccess.toggle()
        })
            .disabled(isBtnDisabled)
//            .padding()
    }
    
    func toggle() {
        isBtnDisabled.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            toggle()
        }
    }
    
}

