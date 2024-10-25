//
//  MPCSetup2FAEnableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.10.2024.
//

import SwiftUI

struct MPCSetup2FAEnableView: View, ViewAnalyticsLogger {

    @Environment(\.mpcWalletsService) private var mpcWalletsService

    var analyticsName: Analytics.ViewName { .setup2FAEnable }
    
    let wallet: WalletEntity
    let mpcMetadata: MPCWalletMetadata
    @State private var secret: String? = nil
    
    @State private var error: Error? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView()
                secretDetailsView()
            }
            .padding(.horizontal, 16)
        }
        .background(Color.backgroundDefault)
        .onAppear(perform: onAppear)
        .displayError($error)
    }
}

private extension MPCSetup2FAEnableView {
    func onAppear() {
        Task {
            do {
//                secret = try await mpcWalletsService.requestOTPToEnable2FA(for: mpcMetadata)
                await Task.sleep(seconds: 0.5)
                secret = "GYZDOMRUMEZTANJSGZTDMOSDFSDVSDC"
            } catch {
                self.error = error
            }
        }
    }
}

private extension MPCSetup2FAEnableView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.enable2FATitle.localized())
                .titleText()
            Text(String.Constants.enable2FASubtitle.localized())
                .subtitleText()
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    @ViewBuilder
    func secretDetailsView() -> some View {
        if let secret = secret {
            VStack(spacing: 24) {
                copySecretView(secret)
                orScanSeparatorView()
            }
        } else {
            loadingSecretView()
        }
    }

    @ViewBuilder
    func loadingSecretView() -> some View {
        ProgressView()
    }

    @ViewBuilder
    func copySecretView(_ secret: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(String.Constants.enable2FACopySecretTitle.localized())
                    .textAttributes(color: .foregroundSecondary, fontSize: 12)
                Text(secret)
                    .textAttributes(color: .foregroundDefault, fontSize: 16)
            }
            .lineLimit(1)
            
            UDButtonView(text: String.Constants.copy.localized(),
                         style: .small(.raisedPrimary), callback: {
                logButtonPressedAnalyticEvents(button: .copy)
                UIPasteboard.general.string = secret
            })
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.backgroundSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color.borderDefault, lineWidth: 1)) 
    }

    @ViewBuilder
    func orScanSeparatorView() -> some View {
        HStack(spacing: 8) {
            HomeExploreSeparatorView()
                .layoutPriority(1)
            Text(String.Constants.enable2FAOrScanQRCode.localized())
                .textAttributes(color: .foregroundSecondary,
                                fontSize: 14,
                                fontWeight: .medium)
                .lineLimit(1)
                .layoutPriority(2)
            HomeExploreSeparatorView()
                .layoutPriority(1)
        }
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockMPC()
    let mpcMetadata = wallet.udWallet.mpcMetadata!
    
    return NavigationStack {
        MPCSetup2FAEnableView(wallet: wallet,
                              mpcMetadata: mpcMetadata)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "arrow.left")
            }
        }
    }
}
