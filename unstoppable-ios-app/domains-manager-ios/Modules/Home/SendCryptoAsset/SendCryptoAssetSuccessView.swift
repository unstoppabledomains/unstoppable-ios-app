//
//  SendCryptoAssetSuccessView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct SendCryptoAssetSuccessView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    @EnvironmentObject var tabRouter: HomeTabRouter

    var asset: Asset
    var analyticsName: Analytics.ViewName { asset.viewName }
    @StateObject private var transactionTracker = TransactionStatusTracker()
    
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
        .animation(.default, value: UUID())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: onAppear)
        .trackAppearanceAnalytics(analyticsLogger: self)
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSuccessView {
    func onAppear() {
        switch asset {
        case .domain(let domain):
            transactionTracker.trackTransactionOf(type: .domainTransfer(domain.name))
        case .token(_, _, let txHash):
            transactionTracker.trackTransactionOf(type: .txHash(txHash))
        }
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
            String.Constants.transferDomainSuccessTitle.localized()
        case .token:
            String.Constants.sendCryptoSuccessTitle.localized()
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
        case .token(let token, let amount, _):
            "\(formatCartPrice(amount.valueOf(type: .usdAmount, for: token))) · \(amount.valueOf(type: .tokenAmount, for: token).formatted(toMaxNumberAfterComa: 6)) \(token.symbol)"
        }
    }
    
    @ViewBuilder
    func subtitleTextView() -> some View {
        Text(currentSubtitle)
            .font(.currentFont(size: 16, weight: .medium))
            .foregroundStyle(Color.foregroundDefault)
            .multilineTextAlignment(.center)
    }
    
    var currentTimeEstimation: String? {
        switch asset {
        case .domain:
            String.Constants.transactionTakesNMinutes.localized(5)
        case .token:
            nil
        }
    }
    
    @ViewBuilder
    func estimateTimeTextView() -> some View {
        if let currentTimeEstimation {
            Text(currentTimeEstimation)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    func actionButtons() -> some View {
        VStack(spacing: 16) {
            if let link = getLinkToTx(transactionTracker.txHash) {
                viewTransactionButton(link: link)
            }
            doneButton()
        }
    }
    
    @ViewBuilder
    func viewTransactionButton(link: String.Links) -> some View {
        UDButtonView(text: String.Constants.viewTransaction.localized(),
                     style: .large(.ghostPrimary),
                     callback: {
            logButtonPressedAnalyticEvents(button: .viewTransaction)
            viewTransaction(link: link)
        })
    }
    
    func getLinkToTx(_ txHash: String?) -> String.Links? {
        guard let txHash else { return nil }
        
        let link: String.Links
        switch asset {
        case .domain(let domain):
            let chain = domain.blockchain ?? .Matic
            link = .scanTransaction(chain: chain.shortCode, transaction: txHash)
        case .token(let token, _, _):
            link = .scanTransaction(chain: token.chain, transaction: txHash)
        }
        guard link.url?.host() != nil else { return nil }
        
        return link
    }
    
    func viewTransaction(link: String.Links) {
        openLink(link)
    }
    
    @ViewBuilder
    func doneButton() -> some View {
        UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                     style: .large(.raisedPrimary),
                     callback: doneAction)
    }
    
    func doneAction() {
        transactionTracker.stopTracking()
        logButtonPressedAnalyticEvents(button: .done)
        tabRouter.sendCryptoInitialData = nil
    }
}

// MARK: - Open methods
extension SendCryptoAssetSuccessView {
    enum Asset {
        case token(token: BalanceTokenUIDescription, amount: SendCryptoAsset.TokenAssetAmountInput, txHash: TxHash)
        case domain(DomainDisplayInfo)
        
        var viewName: Analytics.ViewName {
            switch self {
            case .token:
                return .sendCryptoSuccess
            case .domain:
                return .transferDomainSuccess
            }
        }
    }
}

#Preview {
    SendCryptoAssetSuccessView(asset: .token(token: MockEntitiesFabric.Tokens.mockUIToken(),
                                             amount: .tokenAmount(0.0324), 
                                             txHash: ""))
//    SendCryptoAssetSuccessView(asset: .domain(MockEntitiesFabric.Domains.mockDomainDisplayInfo()))
}
