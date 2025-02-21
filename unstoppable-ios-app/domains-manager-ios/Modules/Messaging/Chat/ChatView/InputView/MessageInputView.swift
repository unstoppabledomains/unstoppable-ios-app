//
//  MessageInputView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct MessageInputView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @EnvironmentObject var viewModel: ChatViewModel

    let input: Binding<String>
    let placeholder: String
    @FocusState.Binding var focused: Bool
    let sendCallback: MainActorCallback
    let additionalActionCallback: @MainActor (AdditionalAction)->()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            if viewModel.canSendAttachments {
                additionalActionsView()
            }
            textFieldView()
            if !input.wrappedValue.isEmpty {
                Button {
                    UDVibration.buttonTap.vibrate()
                    sendCallback()
                } label: {
                    Image.arrowUp24
                        .squareFrame(20)
                        .padding(EdgeInsets(10))
                        .foregroundStyle(Color.foregroundOnEmphasis)
                        .background(Color.backgroundAccentEmphasis)
                        .clipShape(Circle())
                }
            }
        }
        .animation(.linear, value: UUID())
        .padding(.horizontal)
        .padding(EdgeInsets(vertical: 8))
    }
    
    enum AdditionalAction: String, CaseIterable {
        case takePhoto
        case choosePhoto
        
        var title: String {
            switch self {
            case .choosePhoto:
                return String.Constants.choosePhoto.localized()
            case .takePhoto:
                return String.Constants.takePhoto.localized()
            }
        }
        
        var icon: String {
            switch self {
            case .choosePhoto:
                return "photo.on.rectangle"
            case .takePhoto:
                return "camera"
            }
        }
        
        @MainActor
        var isAvailable: Bool {
            switch self {
            case .choosePhoto:
                return true
            case .takePhoto:
                return UnstoppableImagePicker.isCameraAvailable
            }
        }
        
        var analyticButton: Analytics.Button {
            switch self {
            case .takePhoto:
                return .takePhoto
            case .choosePhoto:
                return .choosePhoto
            }
        }
    }
}

// MARK: - Private methods
private extension MessageInputView {
    @MainActor
    @ViewBuilder
    func additionalActionsView() -> some View {
        Menu {
            ForEach(AdditionalAction.allCases.filter { $0.isAvailable }, id: \.self) { action in
                Button {
                    UDVibration.buttonTap.vibrate()
                    logButtonPressedAnalyticEvents(button: action.analyticButton)
                    additionalActionCallback(action)
                } label: {
                    Label(action.title, systemImage: action.icon)
                }
            }
        } label: {
            Image.plusIcon
                .resizable()
                .squareFrame(20)
                .padding(EdgeInsets(10))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .onButtonTap {
            logButtonPressedAnalyticEvents(button: .chatInputActions)
        }
    }
    
    @ViewBuilder
    func textFieldView() -> some View {
        ExpandableTextEditor(text: input, 
                             placeholder: placeholder,
                             focused: $focused)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    struct Preview: View {
        @State var text = ""
        @FocusState var focused: Bool
        
        var body: some View {
            MessageInputView(input: $text,
                             placeholder: "Placeholder",
                             focused: $focused,
                             sendCallback: { },
                             additionalActionCallback: { _ in })
        }
    }
    
    return Preview()
}
