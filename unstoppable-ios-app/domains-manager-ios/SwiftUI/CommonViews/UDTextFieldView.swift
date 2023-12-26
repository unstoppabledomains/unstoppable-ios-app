//
//  UDTextFieldView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

struct UDTextFieldView: View {
    
    @Binding var text: String
    let placeholder: String
    var hint: String? = nil
    var rightViewType: RightViewType = .clear
    var rightViewMode: UITextField.ViewMode = .whileEditing
    var leftViewType: LeftViewType? = nil
    var focusBehaviour: FocusBehaviour = .default
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    @State private var state: TextFieldState = .rest
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.isEnabled) var isEnabled
    
    var body: some View {
        VStack {
            ZStack {
                getTextFieldBackground()
                getTextFieldContent()
                    .sideInsets(16)
            }
            .frame(height: 56)
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: UUID())
        .onAppear {
            switch focusBehaviour {
            case .default:
                return
            case .activateOnAppear:
                isTextFieldFocused = true
            }
        }
    }
    
}

// MARK: - Subviews
private extension UDTextFieldView {
    @ViewBuilder
    func getTextFieldBackground() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(state.backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(state.borderColor, lineWidth: 1)
            }
    }
    
    @ViewBuilder
    func getTextFieldContent() -> some View {
        HStack(spacing: 12) {
            getLeftView()
            getTextFieldWithHint()
            getRightView()
        }
    }
    
    @ViewBuilder
    func getTextFieldWithHint() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let hint {
                Text(hint)
                    .foregroundStyle(state.hintColor)
                    .font(.currentFont(size: 12))
                    .frame(height: isTextFieldVisible ? 16 : 24)
            }
            TextField("", text: $text)
                .foregroundStyle(state.textColor)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .font(.currentFont(size: 16))
                        .foregroundStyle(state.placeholderColor)
                }
                .focused($isTextFieldFocused)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .onChange(of: isTextFieldFocused) { isFocused in
                    if isFocused {
                        // began editing...
                    } else {
                        // ended editing...
                    }
                    setState()
                }
                .frame(height: 24)
        }
    }
}

// MARK: - Right view
private extension UDTextFieldView {
    @ViewBuilder
    func getRightView() -> some View {
        if shouldShowRightView {
            Button {
                UDVibration.buttonTap.vibrate()
                switch rightViewType {
                case .clear:
                    text = ""
                case .inspire(let callback):
                    callback()
                }
            } label: {
                buildRightView()
            }
        }
    }
    
    var shouldShowRightView: Bool {
        switch rightViewMode {
        case .always:
            return true
        case .never:
            return false
        case .whileEditing:
            return isTextFieldFocused
        case .unlessEditing:
            return !isTextFieldFocused
        @unknown default:
            return false
        }
    }
    
    @ViewBuilder
    func buildRightView() -> some View {
        switch rightViewType {
        case .clear:
            buildClearRightView()
        case .inspire:
            buildInspireRightView()
        }
    }
    
    @ViewBuilder
    func buildClearRightView() -> some View {
        Image.crossWhite
            .resizable()
            .squareFrame(20)
            .foregroundStyle(Color.foregroundMuted)
    }
    
    
    @ViewBuilder
    func buildInspireRightView() -> some View {
        HStack(spacing: 8) {
            Text("Inspire")
                .font(.currentFont(size: 16, weight: .medium))
            Image.sparkleIcon
                .resizable()
                .squareFrame(20)
        }
        .foregroundStyle(Color.foregroundAccent)
    }
}

// MARK: - Left view
private extension UDTextFieldView {
    @ViewBuilder
    func getLeftView() -> some View {
        if let leftViewType {
            switch leftViewType {
            case .search:
                getLeftSearchView()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSecondary)
            }
        }
    }
    
    @ViewBuilder
    func getLeftSearchView() -> some View {
        Image.searchIcon
    }
}

// MARK: - Private methods
private extension UDTextFieldView {
    var isTextFieldVisible: Bool {
        true
    }
    
    enum TextFieldState {
        case rest, focused, disabled
        
        var backgroundColor: Color {
            switch self {
            case .rest, .disabled:
                return .backgroundSubtle
            case .focused:
                return .backgroundMuted
            }
        }
        
        var borderColor: Color {
            switch self {
            case .rest, .disabled:
                return .borderDefault
            case .focused:
                return .clear
            }
        }
        
        var hintColor: Color {
            switch self {
            case .rest, .focused:
                return .foregroundSecondary
            case .disabled:
                return .foregroundMuted
            }
        }
        
        var textColor: Color {
            switch self {
            case .rest, .focused:
                return .foregroundDefault
            case .disabled:
                return .foregroundMuted
            }
        }
        var placeholderColor: Color {
            switch self {
            case .rest, .focused:
                return .foregroundSecondary
            case .disabled:
                return .foregroundMuted
            }
        }
    }
    
    func setState() {
        if !isEnabled {
            state = .disabled
        } else if isTextFieldFocused {
            state = .focused
        } else {
            state = .rest
        }
    }
}

// MARK: - RightViewType
extension UDTextFieldView {
    enum RightViewType {
        case clear
        //        case paste
        //        case loading
        //        case success
        case inspire(EmptyCallback)
    }
    
    enum LeftViewType {
        case search
    }
    
    enum FocusBehaviour {
        case `default`
        case activateOnAppear
    }
}

#Preview {
    struct PresenterView: View {
        
        @State var text = ""
        @State var textFieldDisabled = false
        
        var body: some View {
            UDTextFieldView(text: $text,
                            placeholder: "domain.x",
                            hint: nil,
                            rightViewType: .inspire({ }),
                            rightViewMode: .always,
                            leftViewType: .search)
            .disabled(textFieldDisabled)
        }
        
    }
    
    return PresenterView()
}


extension View {
    func placeholder<Content: View>(when shouldShow: Bool,
                                    alignment: Alignment = .leading,
                                    @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
