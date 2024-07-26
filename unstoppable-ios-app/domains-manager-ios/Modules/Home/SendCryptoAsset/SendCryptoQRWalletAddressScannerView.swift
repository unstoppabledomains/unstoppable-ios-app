//
//  QRScannerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import SwiftUI

struct SendCryptoQRWalletAddressScannerView: View, ViewAnalyticsLogger {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    var analyticsName: Analytics.ViewName { .sendCryptoScanQRCode }
    
    @State private var isTorchAvailable = false
    @State private var isTorchOn = false
    @State private var didRecognizeAddress = false
    
    var body: some View {
        ZStack {
            QRScannerView(hint: .walletAddress, 
                          isTorchOn: isTorchOn,
                          onEvent: handleQRScannerViewEvent)
            .ignoresSafeArea()
        }
        .toolbar {
            if isTorchAvailable {
                ToolbarItem(placement: .topBarTrailing) {
                    torchButton()
                }
            }
        }
        .animation(.default, value: UUID())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .passViewAnalyticsDetails(logger: self)
        .navigationTitle(String.Constants.scanQRCodeTitle.localized())
    }
}

// MARK: - Private methods
private extension SendCryptoQRWalletAddressScannerView {
    func handleQRScannerViewEvent(_ event: QRScannerPreviewView.Event) {
        switch event {
        case .didChangeState(let state):
            if case .scanning(let capabilities) = state {
                isTorchAvailable = capabilities.isTorchAvailable
            }
        case .didRecognizeQRCodes(let codes):
            for code in codes {
                if let addressDetails = viewModel.getWalletAddressDetailsFor(address: code) {
                    didRecognizeWalletAddress(addressDetails)
                    return
                }
            }
        case .didFailToSetupCaptureSession:
            return
        }
    }
    
    func didRecognizeWalletAddress(_ addressDetails: SendCryptoAsset.WalletAddressDetails) {
        guard !didRecognizeAddress else { return }
        
        didRecognizeAddress = true
        logAnalytic(event: .didRecognizeQRWalletAddress, parameters: [.wallet: addressDetails.address,
                                                                      .coin: addressDetails.network.shortCode])
        dismiss()
        Vibration.success.vibrate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            viewModel.handleAction(.globalWalletAddressSelected(addressDetails))
        }
    }
}

// MARK: - Private methods
private extension SendCryptoQRWalletAddressScannerView {
    @ViewBuilder
    func torchButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            isTorchOn.toggle()
            logButtonPressedAnalyticEvents(button: .cameraTorch, parameters: [.isOn: String(isTorchOn)])
        } label: {
            currentTorchIcon()
                .squareFrame(24)
        }
    }
    
    @ViewBuilder
    func currentTorchIcon() -> some View {
        if isTorchOn {
            Image.bolt
                .resizable()
                .foregroundStyle(Color.brandElectricYellow)
                .shadow(color: Color(red: 0.9, 
                                     green: 0.98,
                                     blue: 0.2).opacity(0.72),
                        radius: 8,
                        x: 0,
                        y: 2)
        } else {
            Image.boltSlash
                .resizable()
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack {
        SendCryptoQRWalletAddressScannerView()
    }
}


