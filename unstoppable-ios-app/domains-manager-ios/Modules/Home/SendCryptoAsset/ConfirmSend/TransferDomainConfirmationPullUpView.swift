//
//  TransferDomainConfigurationPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

typealias TransferDomainConfirmationCallback = @MainActor (SendCryptoAsset.TransferDomainConfirmationData)->()

struct TransferDomainConfirmationPullUpView: View {
    
    let confirmCallback: TransferDomainConfirmationCallback
    
    @State private var confirmationData = ConfirmationData()
    
    var body: some View {
        VStack(spacing: 24) {
            DismissIndicatorView(color: .foregroundMuted)
            VStack(alignment: .leading, spacing: 16) {
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
private extension TransferDomainConfirmationPullUpView {
    @ViewBuilder
    func confirmRowWith(isOn: Binding<Bool>,
                                title: String,
                                subtitle: String? = nil) -> some View {
        HStack(spacing: 16) {
            // TODO: - Pass analytics button to UDCheckBoxView

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
        }
        .frame(height: 48)
    }
    
    @ViewBuilder
    func warningText() -> some View {
        Text(String.Constants.transferDomainConfirmationHint.localized())
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
private extension TransferDomainConfirmationPullUpView {
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
                await confirmCallback(.init(shouldClearRecords: confirmationData.resetRecords))
            }
        }
    }
}

#Preview {
    TransferDomainConfirmationPullUpView(confirmCallback: { _ in })
}
