//
//  SelectAssetToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendView: View {
    
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    
    @State private var selectedType: SendCryptoAsset.AssetType = .tokens
    @State private var tokens: [BalanceTokenUIDescription] = []
    @State private var domains: [DomainDisplayInfo] = []
    
    var body: some View {
        List {
            assetTypePickerView()
                .listRowSeparator(.hidden)
            selectedAssetsList()
                .listRowSeparator(.hidden)
        }
        .addNavigationTopSafeAreaOffset()
        .navigationTitle(String.Constants.send.localized())
        .listStyle(.plain)
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendView {
    func onAppear() {
        tokens = viewModel.sourceWallet.balance
            .map { BalanceTokenUIDescription.extractFrom(walletBalance: $0) }
            .flatMap({ $0 })
            .filter { $0.balanceUsd > 1 }
            .sorted(by: { lhs, rhs in
            lhs.balanceUsd > rhs.balanceUsd
        })
        
        domains = viewModel.sourceWallet.domains
            .sorted(by: { lhs, rhs in
            lhs.name < rhs.name
        })
    }
    
    @ViewBuilder
    func assetTypePickerView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            UDTabsPickerView(selectedTab: $selectedType,
                             tabs: SendCryptoAsset.AssetType.allCases)
            HomeExploreSeparatorView()
        }
    }
    
    @ViewBuilder
    func selectedAssetsList() -> some View {
        switch selectedType {
        case .tokens:
            tokensListView()
        case .domains:
            domainsListView()
        }
    }
    
    @ViewBuilder
    func tokensListView() -> some View {
        ForEach(tokens) { token in
            selectableTokenRow(token)
        }
    }
    
    @ViewBuilder
    func selectableTokenRow(_ token: BalanceTokenUIDescription) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
        } label: {
            SelectCryptoAssetToSendTokenView(token: token)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        ForEach(domains) { domain in
            selectableDomainRow(domain)
        }
    }
    
    @ViewBuilder
    func selectableDomainRow(_ domain: DomainDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
        } label: {
            SelectCryptoAssetToSendDomainView(domain: domain)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SelectCryptoAssetToSendView()
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
