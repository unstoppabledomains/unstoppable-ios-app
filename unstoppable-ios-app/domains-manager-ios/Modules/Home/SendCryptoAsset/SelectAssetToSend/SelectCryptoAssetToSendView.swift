//
//  SelectAssetToSendView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendView: View, ViewAnalyticsLogger {
        
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    @EnvironmentObject var tabRouter: HomeTabRouter
    
    @State private var searchDomainsKey = ""
    @State private var selectedType: SendCryptoAsset.AssetType = .tokens
    @State private var tokens: [BalanceTokenUIDescription] = []
    @State private var domainsData: HomeWalletView.DomainsSectionData = .init(domainsGroups: [], 
                                                                              subdomains: [],
                                                                              isSearching: false)
    @State private var allDomains: [DomainDisplayInfo] = []
    
    let receiver: SendCryptoAsset.AssetReceiver
    var analyticsName: Analytics.ViewName { .sendCryptoAssetSelection }
    
    var body: some View {
        List {
            assetTypePickerView()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(horizontal: 16))
            selectedAssetsList()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(horizontal: 16))
        }
        .trackAppearanceAnalytics(analyticsLogger: self)
        .addNavigationTopSafeAreaOffset()
        .listRowSpacing(0)
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
            .filter { viewModel.canSendToken($0) }
            .filter { $0.balanceUsd > 1 }
            .sorted(by: { lhs, rhs in
            lhs.balanceUsd > rhs.balanceUsd
        })
        
        allDomains = viewModel.sourceWallet.domains.filter { $0.isUDDomain && $0.isAbleToTransfer }
        setDomainsData()
        setupTitle()
    }
    
    func setupTitle() {
        withAnimation {
            viewModel.navigationState?.setCustomTitle(customTitle: { SendCryptoReceiverInfoTitleView(receiver: receiver) },
                                                      id: UUID().uuidString)
            viewModel.navigationState?.isTitleVisible = true
        }
    }
    
    func setDomainsData() {
        domainsData.setDomains(filteredDomains)
        domainsData.sortDomains(.alphabeticalAZ)
        domainsData.isSearching = !searchDomainsKey.isEmpty
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
                .padding(.init(vertical: 10))
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
        ZStack {
            if !allDomains.isEmpty {
                domainsSearchView()
            }
        }
        domainsContentView()
    }
    
    @ViewBuilder
    func domainsContentView() -> some View {
        HomeWalletsDomainsSectionView(domainsData: $domainsData,
                                      domainSelectedCallback: { domain in
            viewModel.handleAction(.userDomainSelected(.init(receiver: receiver, domain: domain)))
        },
                                      buyDomainCallback: {
            tabRouter.runPurchaseFlow()
        })
    }
    
    @ViewBuilder
    func domainsSearchView() -> some View {
        UDTextFieldView(text: $searchDomainsKey,
                        placeholder: String.Constants.search.localized(),
                        leftViewType: .search,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        height: 36)
        .onChange(of: searchDomainsKey, perform: { _ in
            setDomainsData()
        })
    }
}

#Preview {
    SelectCryptoAssetToSendView(receiver: MockEntitiesFabric.SendCrypto.mockReceiver())
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
