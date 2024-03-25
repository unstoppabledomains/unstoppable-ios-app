//
//  QRScannerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import SwiftUI

struct QRWalletAddressScannerView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel

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
        .navigationTitle(String.Constants.scanQRCodeTitle.localized())
    }
}

// MARK: - Private methods
private extension QRWalletAddressScannerView {
    func handleQRScannerViewEvent(_ event: QRScannerPreviewView.Event) {
        switch event {
        case .didChangeState(let state):
            if case .scanning(let capabilities) = state {
                isTorchAvailable = capabilities.isTorchAvailable
            }
        case .didRecognizeQRCodes(let codes):
            if let walletAddress = codes.first(where: { $0.isValidAddress() }) {
                didRecognizeWalletAddress(walletAddress)
            }
        case .didFailToSetupCaptureSession:
            return
        }
    }
    
    func didRecognizeWalletAddress(_ walletAddress: HexAddress) {
        guard !didRecognizeAddress else { return }
        
        didRecognizeAddress = true
        dismiss()
        viewModel.navPath.removeLast()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            viewModel.handleAction(.globalWalletAddressSelected(walletAddress))
        }
    }
}

// MARK: - Private methods
private extension QRWalletAddressScannerView {
    @ViewBuilder
    func torchButton() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            isTorchOn.toggle()
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
        QRWalletAddressScannerView()
    }
}


