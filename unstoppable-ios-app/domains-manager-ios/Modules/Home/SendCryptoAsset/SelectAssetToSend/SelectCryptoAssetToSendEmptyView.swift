//
//  SelectCryptoAssetToSendEmptyView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.04.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendEmptyView: View {
    
    var assetType: SendCryptoAsset.AssetType
    let actionCallback: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            iconView()
            VStack(spacing: 12) {
                titleView()
                subtitleView()
            }
            actionButton()
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.foregroundSecondary)
        .padding(.top, 40)
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendEmptyView {
    @ViewBuilder
    func iconView() -> some View {
        Image.brushSparkle
            .resizable()
            .squareFrame(48)
    }
  
    @ViewBuilder
    func titleView() -> some View {
        Text(title)
            .font(.currentFont(size: 22, weight: .bold))
    }
    
    var title: String {
        switch assetType {
        case .domains:
            String.Constants.sendAssetNoDomainsTitle.localized()
        case .tokens:
            String.Constants.sendAssetNoTokensTitle.localized()
        }
    }
    
    @ViewBuilder
    func subtitleView() -> some View {
        if let subtitle {
            Text(subtitle)
                .font(.currentFont(size: 16))
        }
    }
    
    var subtitle: String? {
        switch assetType {
        case .domains:
            nil
        case .tokens:
            String.Constants.sendAssetNoTokensSubtitle.localized()
        }
    }
    
    @ViewBuilder
    func actionButton() -> some View {
        if case .tokens = assetType,
           !Constants.isBuyCryptoEnabled {
            EmptyView()
        } else {
            UDButtonView(text: actionButtonTitle,
                         icon: .plusIconNav,
                         style: .medium(.raisedTertiary),
                         callback: actionCallback)
        }
    }
    
    var actionButtonTitle: String {
        switch assetType {
        case .domains:
            String.Constants.buyDomain.localized()
        case .tokens:
            String.Constants.selectPullUpBuyTokensTitle.localized()
        }
    }
}

#Preview {
    SelectCryptoAssetToSendEmptyView(assetType: .tokens,
                                     actionCallback: { })
}
