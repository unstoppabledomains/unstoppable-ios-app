//
//  SelectAssetToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendView: View {
        
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    
    @State private var searchDomainsKey = ""
    @State private var selectedType: SendCryptoAsset.AssetType = .tokens
    @State private var tokens: [BalanceTokenUIDescription] = []
    @State private var allDomains: [DomainDisplayInfo] = []
    
    let receiver: SendCryptoAsset.AssetReceiver
    
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
        
        allDomains = viewModel.sourceWallet.domains
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
            viewModel.handleAction(.userTokenToSendSelected(.init(receiver: receiver,
                                                                  token: token)))
        } label: {
            SelectCryptoAssetToSendTokenView(token: token)
        }
        .buttonStyle(.plain)
    }
    
    var filteredDomains: [DomainDisplayInfo] {
        if searchDomainsKey.isEmpty {
            return allDomains
        } else {
            return allDomains.filter { $0.name.lowercased().contains(searchDomainsKey.lowercased()) }
        }
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        domainsSearchView()
        ForEach(filteredDomains) { domain in
            selectableDomainRow(domain)
        }
    }
    
    @ViewBuilder
    func domainsSearchView() -> some View {
        UDTextFieldView(text: $searchDomainsKey,
                        placeholder: String.Constants.search.localized(),
                        leftViewType: .search,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        height: 36)
    }

    @ViewBuilder
    func selectableDomainRow(_ domain: DomainDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            viewModel.handleAction(.userDomainSelected(domain))
        } label: {
            SelectCryptoAssetToSendDomainView(domain: domain)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SelectCryptoAssetToSendView(receiver: MockEntitiesFabric.SendCrypto.mockReceiver())
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
