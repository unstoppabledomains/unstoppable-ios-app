//
//  SendCryptoAssetSuccessView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct SendCryptoAssetSuccessView: View {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    
    var asset: Asset
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            checkmarkView()
            VStack(spacing: 16) {
                titleTextView()
                VStack(spacing: 32) {
                    subtitleTextView()
                    estimateTimeTextView()
                }
            }
            Spacer()
            actionButtons()
                .padding(.bottom, 16)
        }
        .multilineTextAlignment(.center)
        .padding(16)
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSuccessView {
    @ViewBuilder
    func checkmarkView() -> some View {
        Image.check
            .resizable()
            .padding(12)
            .squareFrame(56)
            .foregroundStyle(Color.black)
            .background(Color.foregroundAccent)
            .clipShape(Circle())
    }
    
    var currentTitle: String {
        switch asset {
        case .domain:
            "Domain transfer\nhas started"
        case .token:
            "Successfully sent"
        }
    }
    
    @ViewBuilder
    func titleTextView() -> some View {
        Text(currentTitle)
            .font(.currentFont(size: 32, weight: .bold))
            .foregroundStyle(Color.foregroundDefault)
    }
    
    var currentSubtitle: String {
        switch asset {
        case .domain(let domain):
            domain.name
        case .token:
            "Successfully sent"
        }
    }
    
    @ViewBuilder
    func subtitleTextView() -> some View {
        Text(currentSubtitle)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .multilineTextAlignment(.center)
    }
    
    var currentTimeEstimation: String {
        switch asset {
        case .domain:
            "This transaction usually takes ~5 minutes."
        case .token:
            "This transaction usually takes ~5 minutes."
        }
    }
    
    @ViewBuilder
    func estimateTimeTextView() -> some View {
        Text(currentTimeEstimation)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundSecondary)
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    func actionButtons() -> some View {
        VStack {
            viewTransactionButton()
            doneButton()
        }
    }
    
    @ViewBuilder
    func viewTransactionButton() -> some View {
        UDButtonView(text: String.Constants.viewTransaction.localized(),
                     style: .large(.ghostPrimary),
                     callback: viewTransaction)
    }
    
    func viewTransaction() {
        
    }
    
    @ViewBuilder
    func doneButton() -> some View {
        UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                     style: .large(.raisedPrimary),
                     callback: doneAction)
    }
    
    func doneAction() {
        
    }
}

// MARK: - Open methods
extension SendCryptoAssetSuccessView {
    enum Asset {
        case token(token: BalanceTokenUIDescription, amount: SendCryptoAsset.TokenAssetAmountInput)
        case domain(DomainDisplayInfo)
    }
}

#Preview {
    SendCryptoAssetSuccessView(asset: .domain(MockEntitiesFabric.Domains.mockDomainDisplayInfo()))
}
