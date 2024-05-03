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
    @State private var tokens: [BalanceTokenToSend] = []
    @State private var notAddedTokens: [BalanceTokenToSend] = []
    @State private var domainsData: HomeWalletView.DomainsSectionData = .init(domainsGroups: [],
                                                                              subdomains: [],
                                                                              isSearching: false)
    @State private var allDomains: [DomainDisplayInfo] = []
    @State private var pullUp: ViewPullUpConfigurationType?

    let receiver: SendCryptoAsset.AssetReceiver
    var analyticsName: Analytics.ViewName { .sendCryptoAssetSelection }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.toWallet: receiver.walletAddress,
                                                                         .fromWallet: viewModel.sourceWallet.address] }
    var body: some View {
        List {
            assetTypePickerView()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(horizontal: 16))
            selectedAssetsList()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(horizontal: 16))
        }
        .sectionSpacing(0)
        .onChange(of: selectedType, perform: { newValue in
            logButtonPressedAnalyticEvents(button: .assetTypeSwitcher, 
                                           parameters: [.assetType : newValue.rawValue])
        })
        .trackAppearanceAnalytics(analyticsLogger: self)
        .addNavigationTopSafeAreaOffset()
        .viewPullUp($pullUp)
        .listRowSpacing(0)
        .listStyle(.plain)
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension SelectCryptoAssetToSendView {
    func onAppear() {
        let tokens = viewModel.sourceWallet.balance
            .map { BalanceTokenUIDescription.extractFrom(walletBalance: $0) }
            .flatMap({ $0 })
            .filter { viewModel.canSendToken($0) }
            .filter { $0.balanceUsd > 0 }
            .sorted(by: { lhs, rhs in
            lhs.balanceUsd > rhs.balanceUsd
        })
            .map { createTokenToSendFrom(token: $0) }
        
        self.notAddedTokens = tokens.filter { $0.address == nil }
        self.tokens = tokens.filter { $0.address != nil }
        
        allDomains = viewModel.sourceWallet.domains.filter { $0.isUDDomain && $0.isAbleToTransfer }
        setDomainsData()
        setupTitle()
    }
    
    func createTokenToSendFrom(token: BalanceTokenUIDescription) -> BalanceTokenToSend {
        if receiver.domainName != nil {
            let address = receiver.addressFor(symbol: token.symbol)
            return BalanceTokenToSend(token: token, address: address)
        }
        
        return BalanceTokenToSend(token: token, address: receiver.walletAddress)
    }
    
    struct BalanceTokenToSend: Identifiable {
        var id: String { token.id }
        
        let token: BalanceTokenUIDescription
        let address: String?
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
        if tokens.isEmpty,
           notAddedTokens.isEmpty {
            SelectCryptoAssetToSendEmptyView(assetType: .tokens,
                                             actionCallback: {
                tabRouter.runBuyCryptoFlowTo(wallet: viewModel.sourceWallet)
            })
        } else {
            if tokens.isEmpty {
                noTokensToSendSectionView()
            } else {
                ForEach(tokens) { token in
                    selectableTokenRow(token)
                }
            }
            
            if !notAddedTokens.isEmpty {
                if !tokens.isEmpty {
                    HomeExploreSeparatorView()
                    notAddedTokensSectionHeader()
                }
                ForEach(notAddedTokens) { token in
                    selectableTokenRow(token)
                }
            }
        }
    }
    
    @ViewBuilder
    func noTokensToSendSectionView() -> some View {
        VStack(spacing: 16) {
            Image.squareInfo
                .resizable()
                .squareFrame(32)
                .foregroundStyle(Color.foregroundMuted)
            VStack(spacing: 8) {
                Text(String.Constants.noRecordsToSendAnyCryptoTitle.localized(receiver.domainName ?? ""))
                    .font(.currentFont(size: 20, weight: .bold))
                Text(String.Constants.noRecordsToSendCryptoMessage.localized())
                    .font(.currentFont(size: 14, weight: .regular))
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.foregroundSecondary)
            
            UDButtonView(text: String.Constants.chatToNotify.localized(),
                         icon: .messagesIcon,
                         style: .medium(.raisedPrimary)) {
                chatToNotifyButtonPressed()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    func chatToNotifyButtonPressed() {
        tabRouter.startMessagingWith(walletAddress: receiver.walletAddress,
                                     domainName: receiver.domainName,
                                     by: viewModel.sourceWallet)
       
    }
    
    @ViewBuilder
    func notAddedTokensSectionHeader() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .noRecordsAdded)
            showNotAddedCurrenciesPullUp()
        } label: {
            HStack {
                Text(String.Constants.noRecordsToSendCryptoSectionHeader.localized(receiver.domainName ?? ""))
                    .foregroundStyle(Color.foregroundSecondary)
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundMuted)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func selectableTokenRow(_ token: BalanceTokenToSend) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: .cryptoToken,
                                           parameters: [.token : token.id])
            didSelectBalanceTokenToSend(token)
        } label: {
            SelectCryptoAssetToSendTokenView(token: token.token)
                .padding(.init(vertical: 10))
                .opacity(token.address != nil ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }
    
    func didSelectBalanceTokenToSend(_ token: BalanceTokenToSend) {
        if let address = token.address {
            viewModel.handleAction(.userTokenToSendSelected(.init(receiver: receiver,
                                                                  token: token.token,
                                                                  receiverAddress: address)))
        } else {
            showNotAddedCurrenciesPullUp()
        }
    }
    
    func showNotAddedCurrenciesPullUp() {
        pullUp = .default(.showUserDidNotSetRecordToDomainToSendCryptoPullUp(domainName: receiver.domainName ?? "",
                                                                             chatCallback: chatToNotifyButtonPressed))
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
        if !allDomains.isEmpty {
            domainsSearchView()
            domainsContentView()
        } else {
            SelectCryptoAssetToSendEmptyView(assetType: .domains,
                                             actionCallback: tabRouter.runPurchaseFlow)
        }
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
                        height: 36,
                        focusedStateChangedCallback: { isFocused in
            logAnalytic(event: isFocused ? .didStartSearching : .didStopSearching)
        })
        .onChange(of: searchDomainsKey, perform: { text in
            logAnalytic(event: .didSearch, parameters: [.value : text])
            setDomainsData()
        })
    }
}

#Preview {
    SelectCryptoAssetToSendView(receiver: MockEntitiesFabric.SendCrypto.mockReceiver())
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
