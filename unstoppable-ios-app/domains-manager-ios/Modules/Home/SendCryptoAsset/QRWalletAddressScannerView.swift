//
//  QRScannerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import SwiftUI

struct QRWalletAddressScannerView: View {

    @State private var isTorchOn = false
    
    var body: some View {
        ZStack {
            QRScannerView(hint: .walletAddress) { event in
                
            }
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                torchButton()
            }
        }
        .animation(.default, value: UUID())
        .navigationTitle(String.Constants.scanQRCodeTitle.localized())
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
            Image(systemName: "bolt.fill")
                .resizable()
                .foregroundStyle(Color.brandElectricYellow)
                .shadow(color: Color(red: 0.9, green: 0.98, blue: 0.2).opacity(0.72), radius: 8, x: 0, y: 2)
        } else {
            Image(systemName: "bolt.slash")
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


