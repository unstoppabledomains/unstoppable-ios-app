//
//  PurchaseMPCWalletAuthView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2024.
//

import SwiftUI

struct PurchaseMPCWalletAuthView: View, ViewAnalyticsLogger {
    
    @EnvironmentObject var viewModel: PurchaseMPCWalletViewModel
    var analyticsName: Analytics.ViewName { .unspecified }
    
    var body: some View {
        ScrollView {
            titleView()
                .padding(.bottom, 24)
            loginOptionsListView()
        }
        .padding()
    }
}

// MARK: - Private methods
private extension PurchaseMPCWalletAuthView {
   

}

// MARK: - Private methods
private extension PurchaseMPCWalletAuthView {
    @ViewBuilder
    func titleView() -> some View {
        VStack(spacing: 16) {
            Text("Select authorisation method")
                .titleText()
            Text("Very meaningful subtitle")
                .subtitleText()
        }
        .multilineTextAlignment(.center)
    }
    
    var availableLoginProviders: [LoginProvider] { [.email, .google, .twitter] }
    
    @ViewBuilder
    func loginOptionsListView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(availableLoginProviders, id: \.self) { provider in
                    listViewFor(provider: provider)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(provider: LoginProvider) -> some View {
        UDCollectionListRowButton(content: {
            loginOptionRowFor(provider: provider)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            logAnalytic(event: .websiteLoginOptionSelected,
                        parameters: [.websiteLoginOption: provider.rawValue])
            viewModel.handleAction(.authWithProvider(provider))
        })
        .padding(EdgeInsets(4))
    }
    
    @ViewBuilder
    func loginOptionRowFor(provider: LoginProvider) -> some View {
        UDListItemView(title: String.Constants.loginWithProviderN.localized(provider.title),
                       imageType: .uiImage(provider.icon),
                       imageStyle: .centred())
        .frame(height: UDListItemView.height)
    }
}

#Preview {
    PurchaseMPCWalletAuthView()
}
