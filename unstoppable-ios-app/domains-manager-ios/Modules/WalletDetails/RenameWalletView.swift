//
//  RenameWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.05.2024.
//

import SwiftUI

struct RenameWalletView: View, ViewAnalyticsLogger, WalletDataValidator {
    
    @Environment(\.dismiss) var dismiss
    
    var analyticsName: Analytics.ViewName { .renameWallet }
    
    let wallet: WalletEntity
    
    @State private var walletName = ""
    @FocusState var focused: Bool

    var body: some View {
        NavigationStack {
            contentView()
                .padding(.horizontal, 16)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseButtonView {
                            logButtonPressedAnalyticEvents(button: .close)
                            dismiss()
                        }
                    }
                }
                .onAppear(perform: onAppear)
        }
    }
}

// MARK: - Private methods
private extension RenameWalletView {
    func onAppear() {
        setInitialWalletName()
        focused = true
    }
    
    func setInitialWalletName() {
        let displayInfo = wallet.displayInfo
        switch displayInfo.source {
        case .locallyGenerated:
            walletName = displayInfo.name
        case .external(let walletMakeName, _):
            walletName = displayInfo.isNameSet ? displayInfo.name : walletMakeName
        case .imported, .mpc:
            if displayInfo.isNameSet {
                walletName = displayInfo.name
            }
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        VStack(spacing: 24) {
            WalletSourceImageView(displayInfo: wallet.displayInfo)
            VStack(spacing: 16) {
                textField()
                Text(wallet.address.walletAddressTruncated)
                    .textAttributes(color: .foregroundSecondary, fontSize: 16)
                if case .failure(let error) = isNameValid(walletName, for: wallet.displayInfo) {
                    errorView(error)
                }
            }
            Spacer()
            doneButton()
                .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    func textField() -> some View {
        TextField("", text: $walletName, prompt: Text(String.Constants.walletNamePlaceholder.localized()))
            .multilineTextAlignment(.center)
            .textAttributes(color: .foregroundDefault,
                            fontSize: 32,
                            fontWeight: .bold)
            .tint(Color.foregroundDefault)
            .focused($focused)
    }
    
    @ViewBuilder
    func errorView(_ error: WalletNameValidationError) -> some View {
        if let message = error.message {
            HStack(spacing: 8) {
                Image.alertCircle
                    .resizable()
                    .squareFrame(20)
                Text(message)
            }
            .foregroundStyle(Color.foregroundDanger)
        }
    }
    
    var isValidInput: Bool {
        switch isNameValid(walletName, for: wallet.displayInfo) {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    @ViewBuilder
    func doneButton() -> some View {
        UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                     style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .done)
            doneButtonPressed()
        }
                     .disabled(!isValidInput)
    }
    
    func doneButtonPressed() {
        appContext.udWalletsService.rename(wallet: wallet.udWallet, with: walletName)
        dismiss()
    }
}

#Preview {
    RenameWalletView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
