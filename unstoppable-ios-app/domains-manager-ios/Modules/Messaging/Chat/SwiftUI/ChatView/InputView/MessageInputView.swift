//
//  MessageInputView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct MessageInputView: View {
    
    let input: Binding<String>
    let placeholder: String
    @FocusState.Binding var focused: Bool
    let sendCallback: MainActorCallback
    let additionalActionCallback: @MainActor (AdditionalAction)->()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            Menu {
                ForEach(AdditionalAction.allCases.filter { $0.isAvailable }, id: \.self) { action in
                    Button {
                        UDVibration.buttonTap.vibrate()
                        additionalActionCallback(action)
                    } label: {
                        Label(action.title, systemImage: action.icon)
                    }
                }
            } label: {
                Image.plusIcon18
                    .resizable()
                    .squareFrame(20)
                    .padding(EdgeInsets(10))
                    .foregroundStyle(Color.foregroundSecondary)
            }
            .onButtonTap {
//                logButtonPressedAnalyticEvents(button: action.analyticButton)
            }
            
            textFieldView()
            
            if !input.wrappedValue.isEmpty {
                Button {
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
    }
}

// MARK: - Private methods
private extension MessageInputView {
    @ViewBuilder
    func textFieldView() -> some View {
        ExpandableTextEditor(text: input, 
                             placeholder: placeholder,
                             focused: $focused)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
