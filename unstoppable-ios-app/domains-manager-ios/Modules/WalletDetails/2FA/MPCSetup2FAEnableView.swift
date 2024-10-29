//
//  MPCSetup2FAEnableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.10.2024.
//

import SwiftUI

struct MPCSetup2FAEnableView: View, ViewAnalyticsLogger {

    @Environment(\.mpcWalletsService) private var mpcWalletsService
    @Environment(\.imageLoadingService) private var imageLoadingService
    @EnvironmentObject var tabRouter: HomeTabRouter

    var analyticsName: Analytics.ViewName { .setup2FAEnable }
    
    let mpcMetadata: MPCWalletMetadata
    @State private var setupDetails: MPCWallet2FASetupDetails? = nil
    @State private var qrCodeImage: UIImage? = nil
    @State private var error: Error? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 32) {
                    headerView()
                    secretDetailsView()
                }
                .padding(.bottom, 60)
            }
            continueButtonView()
        }
        .padding(.horizontal, 16)
        .background(Color.backgroundDefault)
        .onAppear(perform: onAppear)
        .animation(.default, value: UUID())
        .displayError($error)
    }
}

private extension MPCSetup2FAEnableView {
    func onAppear() {
        loadSecret()
    }
    
    func loadSecret() {
        Task {
            do {
                let setupDetails = try await mpcWalletsService.request2FASetupDetails(for: mpcMetadata)
                self.setupDetails = setupDetails
                
                loadQRCodeFor(setupDetails: setupDetails)
            } catch {
                self.error = error
            }
        }
    }

    func loadQRCodeFor(setupDetails: MPCWallet2FASetupDetails) {
        Task {
            let issuer = "Unstoppable"
            let urlString = "otpauth://totp/\(setupDetails.email)?secret=\(setupDetails.secret)&issuer=\(issuer)"
            
            if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: encodedString) {
            qrCodeImage = await imageLoadingService.loadImage(from: .qrCode(url: url,
                                                                          options: []),
                                                            downsampleDescription: nil)
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
        if let setupDetails {
            VStack(spacing: 24) {
                copySecretView(setupDetails.secret)
                orScanSeparatorView()
                qrCodeView()
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

    @ViewBuilder
    func qrCodeView() -> some View {
        if let qrCodeImage = qrCodeImage {
            Image(uiImage: qrCodeImage)
                .resizable()
                .scaledToFit()
                .squareFrame(200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            ProgressView()
        }
    }

    @ViewBuilder
    func continueButtonView() -> some View {
        if setupDetails != nil {
            UDButtonView(text: String.Constants.continue.localized(),
                         style: .large(.raisedPrimary), callback: {
                logButtonPressedAnalyticEvents(button: .continue)
                moveToNextScreen()
            })
        }
    }
    
    func moveToNextScreen() {
        tabRouter.walletViewNavPath.append(.mpcSetup2FAEnableConfirm(mpcMetadata: mpcMetadata))
    }
}

#Preview {
    let wallet = MockEntitiesFabric.Wallet.mockMPC()
    let mpcMetadata = wallet.udWallet.mpcMetadata!
    
    return NavigationStack {
        MPCSetup2FAEnableView(mpcMetadata: mpcMetadata)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Image(systemName: "arrow.left")
            }
        }
    }
}
