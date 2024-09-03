//
//  PurchaseMPCWalletTakeoverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2024.
//

import SwiftUI

struct PurchaseMPCWalletTakeoverEmailView: View, UserDataValidator, MPCWalletPasswordValidator, ViewAnalyticsLogger {
    
    @Environment(\.claimMPCWalletService) private var claimMPCWalletService

    let analyticsName: Analytics.ViewName
    let emailCallback: (String)->()
    @State private var emailInput: String = ""
    @State private var emailConfirmationInput: String = ""
    @State private var isEmailFocused = true
    @State private var isLoading = false
    @State private var error: Error?
    @State private var emailInUseState: EmailInUseVerificationState = .unverified
    @StateObject private var debounceObject = DebounceObject()
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: isIPSE ? 16 : 32) {
                    headerView()
                    VStack(alignment: .leading, spacing: isIPSE ? 8 : 24) {
                        emailInputView()
                        emailConfirmationInputView()
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 58)
            }
            .scrollIndicators(.hidden)
            
            actionButtonContainerView()
            .edgesIgnoringSafeArea(.bottom)
        }
        .onReceive(KeyboardService.shared.keyboardFramePublisher.receive(on: DispatchQueue.main)) { keyboardFrame in
            keyboardHeight = keyboardFrame.height
        }
        .animation(.default, value: UUID())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .onAppear(perform: onAppear)
        .displayError($error)
    }
    
    @ViewBuilder
    func actionButtonContainerView() -> some View {
        VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .frame(height: 16)
                .foregroundStyle(LinearGradient(colors: [.black, .clear], startPoint: .bottom, endPoint: .top))
            actionButtonView()
                .padding(.bottom, keyboardHeight + 16)
                .padding(.horizontal, 16)
                .background(Color.black)
        }
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletTakeoverEmailView {
    func onAppear() {
        debounceObject.text = emailInput
        checkIfEmailAlreadyInUseIfNeeded()
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.enterEmailTitle.localized())
                .font(.currentFont(size: 32, weight: .bold))
                .foregroundStyle(Color.foregroundDefault)
                .multilineTextAlignment(.center)
            Text(String.Constants.mpcTakeoverCredentialsSubtitle.localizedMPCProduct())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func emailInputView() -> some View {
        VStack(spacing: 8) {
            UDTextFieldView(text: $debounceObject.text,
                            placeholder: "name@mail.com",
                            hint: String.Constants.email.localized(),
                            focusBehaviour: .activateOnAppear,
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            textContentType: .username,
                            autocorrectionDisabled: true,
                            isErrorState: emailVerificationError != nil,
                            focusedStateChangedCallback: { isFocused in
                isEmailFocused = isFocused
                if !isFocused {
                    checkIfEmailAlreadyInUseIfNeeded()
                }
            })
            .onChange(of: debounceObject.debouncedText) { text in
                emailInput = text.trimmedSpaces
                checkIfEmailAlreadyInUseIfNeeded()
            }
            if let emailVerificationError {
                incorrectEmailIndicatorView(error: emailVerificationError)
            }
        }
    }
    
    @ViewBuilder
    func emailConfirmationInputView() -> some View {
        UDTextFieldView(text: $emailConfirmationInput,
                        placeholder: String.Constants.confirmEmail.localized(),
                        focusBehaviour: .default,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        textContentType: .username,
                        autocorrectionDisabled: true)
    }
    
    var emailVerificationError: EmailVerificationError? {
        if case .inUse = emailInUseState {
            return .alreadyInUse
        } else if case .failed = emailInUseState {
            return .failedToVerifyInUse
        } else if !isEmailFocused && !isValidEmailEntered {
            return .incorrectFormat
        }
        return nil
    }
    
    @ViewBuilder
    func incorrectEmailIndicatorView(error: EmailVerificationError) -> some View {
        HStack(spacing: 8) {
            Image.alertCircle
                .resizable()
                .squareFrame(16)
            Text(error.title)
                .font(.currentFont(size: 12, weight: .medium))
            Spacer()
        }
        .foregroundStyle(Color.foregroundDanger)
        .padding(.leading, 16)
    }
    
    var isActionButtonDisabled: Bool {
        !isValidEmailEntered || !isEmailConfirmed || !isVerifiedEmailEntered
    }
    
    var isValidEmailEntered: Bool {
        isEmailValid(emailInput)
    }
    
    var isVerifiedEmailEntered: Bool {
        if case .verified(let value) = emailInUseState {
            return emailInput == value
        }
        return false
    }
    
    var isEmailConfirmed: Bool {
        emailInput == emailConfirmationInput
    }
    
    @ViewBuilder
    func actionButtonView() -> some View {
        if case .failed = emailInUseState {
            tryAgainValidateEmailButton()
        } else {
            continueButton()
        }
    }
    
    @ViewBuilder
    func continueButton() -> some View {
        UDButtonView(text: String.Constants.continue.localized(),
                     style: .large(.raisedPrimary),
                     isLoading: isLoading,
                     callback: actionButtonPressed)
        .disabled(isActionButtonDisabled)
    }
   
    func actionButtonPressed() {
        logButtonPressedAnalyticEvents(button: .continue)
        Task {
            isLoading = true
            do {
                // Send email action
                let email = emailInput
                try await claimMPCWalletService.sendVerificationCodeTo(email: email)
                emailCallback(email)
            } catch {
                logAnalytic(event: .sendClaimMPCCodeError,
                            parameters: [.error: error.localizedDescription])
                self.error = error
            }
            isLoading = false
        }
    }
    
    @ViewBuilder
    func tryAgainValidateEmailButton() -> some View {
        UDButtonView(text: String.Constants.tryAgain.localized(),
                     style: .large(.raisedPrimary),
                     callback: tryAgainValidateEmailButtonPressed)
    }
    
    func tryAgainValidateEmailButtonPressed() {
        logButtonPressedAnalyticEvents(button: .tryAgain)
        checkIfEmailAlreadyInUseIfNeeded()
    }
    
    enum EmailVerificationError {
        case incorrectFormat
        case alreadyInUse
        case failedToVerifyInUse
        
        var title: String {
            switch self {
            case .incorrectFormat:
                String.Constants.incorrectEmailFormat.localized()
            case .alreadyInUse:
                String.Constants.mpcWalletEmailInUseMessage.localized()
            case .failedToVerifyInUse:
                String.Constants.mpcWalletEmailInUseCantVerifyMessage.localized()
            }
        }
    }
    
    func checkIfEmailAlreadyInUseIfNeeded() {
        guard !isVerifiedEmailEntered else { return }
        
        switch emailInUseState {
        case .inUse, .failed:
            emailInUseState = .unverified
        default:
            Void()
        }
        
        Task {
            let email = emailInput
            do {
                let isValid = try await claimMPCWalletService.validateEmailIsAvailable(email: email)
                
                if isValid {
                    emailInUseState = .verified(email)
                } else {
                    emailInUseState = .inUse
                    logAnalytic(event: .mpcEmailInUseEntered)
                }
            } catch {
                emailInUseState = .failed
            }
        }
    }
    
    enum EmailInUseVerificationState {
        case unverified
        case verified(String)
        case inUse
        case failed
    }
}

#Preview {
    PurchaseMPCWalletTakeoverEmailView(analyticsName: .unspecified,
                                             emailCallback: { _ in })
}
