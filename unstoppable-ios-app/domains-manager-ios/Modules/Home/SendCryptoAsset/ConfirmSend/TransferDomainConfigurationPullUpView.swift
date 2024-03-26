//
//  TransferDomainConfigurationPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct TransferDomainConfigurationPullUpView: View {
    
    let confirmCallback: MainActorCallback
    
    @State private var confirmationData = ConfirmationData()
    
    var body: some View {
        VStack(spacing: 24) {
            DismissIndicatorView(color: .foregroundMuted)
            VStack(spacing: 16) {
                confirmRowWith(isOn: $confirmationData.isConsentNotExchangeConfirmed,
                               title: String.Constants.transferConsentNotExchange.localized())
                HomeExploreSeparatorView()
                confirmRowWith(isOn: $confirmationData.isConsentValidAddressConfirmed,
                               title: String.Constants.transferConsentValidAddress.localized())
                HomeExploreSeparatorView()
                confirmRowWith(isOn: $confirmationData.resetRecords,
                               title: String.Constants.clearRecordsUponTransfer.localized(),
                               subtitle: String.Constants.optional.localized())
                HomeExploreSeparatorView()
                warningText()
            }
            confirmButton()
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundDefault)
        .animation(.default, value: UUID())
    }
    
}

// MARK: - Private methods
private extension TransferDomainConfigurationPullUpView {
    @ViewBuilder
    func confirmRowWith(isOn: Binding<Bool>,
                                title: String,
                                subtitle: String? = nil) -> some View {
        HStack(spacing: 16) {
            UDCheckBoxView(isOn: isOn)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                if let subtitle {
                    Text(subtitle)
                        .font(.currentFont(size: 14))
                        .foregroundStyle(Color.foregroundSecondary)
                }
            }
            Spacer()
        }
        .frame(height: 48)
    }
    
    @ViewBuilder
    func warningText() -> some View {
        Text("By clicking, you agree to transfer ownership of this domain, understanding this action is irreversible.")
            .font(.currentFont(size: 13))
            .foregroundStyle(Color.foregroundSecondary)
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func confirmButton() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     icon: confirmIcon,
                     style: .large(.raisedPrimary),
                     callback: confirmTransfer)
        .disabled(!confirmationData.isReadyToTransfer)
    }
    
    var confirmIcon: Image? {
        if User.instance.getSettings().touchIdActivated,
           let icon = appContext.authentificationService.biometricIcon {
            return Image(uiImage: icon)
        }
        return nil
    }
}

// MARK: - Private methods
private extension TransferDomainConfigurationPullUpView {
    struct ConfirmationData {
        var isConsentNotExchangeConfirmed: Bool = false
        var isConsentValidAddressConfirmed: Bool = false
        var resetRecords: Bool = true
        
        var isReadyToTransfer: Bool {
            isConsentNotExchangeConfirmed && isConsentValidAddressConfirmed
        }
    }
    
    func confirmTransfer() {
        Task {
            guard let view = await appContext.coreAppCoordinator.topVC else { return }
            do {
                try await appContext.authentificationService.verifyWith(uiHandler: view, purpose: .confirm)
                await confirmCallback()
            }
        }
    }
}

#Preview {
    TransferDomainConfigurationPullUpView(confirmCallback: { })
}
