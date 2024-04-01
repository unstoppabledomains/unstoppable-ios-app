//
//  SendCryptoSelectReceiverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI
import Combine

struct SendCryptoAssetSelectReceiverView: View, ViewAnalyticsLogger {
    
    
    @Environment(\.domainProfilesService) var domainProfilesService
    @Environment(\.walletsDataService) var walletsDataService
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    var analyticsName: Analytics.ViewName { .sendCryptoReceiverSelection }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.fromWallet: viewModel.sourceWallet.address] }

    @State private var userWallets: [WalletEntity] = []
    @State private var followingList: [DomainName] = []
    @State private var globalProfiles: [SearchDomainProfile] = []
    @StateObject private var debounceObject = DebounceObject()
    @State private var inputText: String = ""
    @State private var isLoadingGlobalProfiles = false

    @State private var socialRelationshipDetailsPublisher: AnyCancellable?
    private let searchService = DomainsGlobalSearchService()
    
    var body: some View {
        List {
            inputFieldView()
                .listRowSeparator(.hidden)
            scanQRView()
            userWalletsSection()
            followingsSection()
            globalSearchResultSection()
        }
        .listStyle(.plain)
        .animation(.default, value: UUID())
        .navigationTitle(String.Constants.send.localized())
        .trackAppearanceAnalytics(analyticsLogger: self)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                closeButton()
            }
        }
        .task {
            userWallets = appContext.walletsDataService.wallets.filter({ $0.address != viewModel.sourceWallet.address })
            socialRelationshipDetailsPublisher = await domainProfilesService.publisherForWalletDomainProfileDetails(wallet: viewModel.sourceWallet)
                .receive(on: DispatchQueue.main)
                .sink { relationshipDetails in
                    followingList = relationshipDetails.socialDetails?.getFollowersListFor(relationshipType: .following) ?? []
                }
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSelectReceiverView {
    func onAppear() {
        withAnimation {
            viewModel.navigationState?.isTitleVisible = false
        }
    }
    
    @ViewBuilder
    func closeButton() -> some View {
        CloseButtonView {
            logButtonPressedAnalyticEvents(button: .close)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    @ViewBuilder
    func inputFieldView() -> some View {
        UDTextFieldView(text: $debounceObject.text,
                        placeholder: String.Constants.domainOrAddress.localized(),
                        hint: String.Constants.to.localized() + ":",
                        rightViewType: .paste,
                        rightViewMode: .always,
                        autocapitalization: .never,
                        autocorrectionDisabled: true)
        .onChange(of: debounceObject.debouncedText) { text in
            inputText = text.lowercased().trimmedSpaces
            searchForGlobalProfiles()
        }
    }
    
    @ViewBuilder
    func scanQRView() -> some View {
        selectableRowView {
            UDListItemView(title: String.Constants.scanQRCodeTitle.localized(),
                           titleColor: .foregroundDefault,
                           subtitle: nil,
                           subtitleStyle: .default,
                           value: nil,
                           imageType: .image(.qrBarCodeIcon),
                           imageStyle: .centred(offset: .init(8),
                                                foreground: .foregroundDefault,
                                                background: .backgroundMuted2,
                                                bordered: true),
                           rightViewStyle: nil)
        } callback: {
            logButtonPressedAnalyticEvents(button: .qrCode)
            viewModel.handleAction(.scanQRSelected)
        }
        .listRowSeparator(.hidden)
    }
    
    var filteredWallets: [WalletEntity] {
        if inputText.isEmpty {
            return userWallets
        } else {
            return userWallets.filter { $0.profileDomainName?.contains(inputText.lowercased()) == true }
        }
    }
    
    var shouldShowWalletsSection: Bool { !filteredWallets.isEmpty }
    
    @ViewBuilder
    func userWalletsSection() -> some View {
        if !userWallets.isEmpty {
            Section {
                if shouldShowWalletsSection {
                    ForEach(filteredWallets) { wallet in
                        selectableUserWalletView(wallet: wallet)
                    }
                }
            } header: {
                if shouldShowWalletsSection {
                    sectionHeaderViewWith(title: String.Constants.yourWallets.localized())
                }
            }
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    func selectableUserWalletView(wallet: WalletEntity) -> some View {
        selectableRowView {
            SendCryptoAssetSelectReceiverWalletRowView(wallet: wallet)
        } callback: {
            logAnalytic(event: .userWalletPressed, parameters: [.wallet: wallet.address])
            viewModel.handleAction(.userWalletSelected(wallet))
        }
    }
    
    @ViewBuilder
    func followingsSection() -> some View {
        if !followingList.isEmpty, !isSearchingInProgress {
            Section {
                ForEach(followingList, id: \.self) { following in
                    selectableFollowingView(following: following)
                }
            } header: {
                sectionHeaderViewWith(title: String.Constants.following.localized())
            }
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    func selectableFollowingView(following: DomainName) -> some View {
        selectableRowView {
            SendCryptoAssetSelectReceiverFollowingRowView(domainName: following)
        } callback: {
            logAnalytic(event: .followingProfilePressed, parameters: [.domainName : following])
            guard let profile = domainProfilesService.getCachedDomainProfileDisplayInfo(for: following) else {
                Debugger.printFailure("Failed to get cached domain profile for following: \(following)")
                return
            }
            viewModel.handleAction(.followingDomainSelected(profile))
        }
    }
    
    @ViewBuilder
    func globalSearchResultSection() -> some View {
        if isSearchingInProgress,
           !isLoadingGlobalProfiles {
            globalSearchResultOrEmptyView()
                .listRowSeparator(.hidden)
        }
    }
    
    enum GlobalSearchResult {
        case profiles([SearchDomainProfile])
        case fullAddress(HexAddress)
    }
    
    func getCurrentGlobalSearchResult() -> GlobalSearchResult? {
        if !globalProfiles.isEmpty {
            return .profiles(globalProfiles)
        } else if inputText.isValidAddress() {
            return .fullAddress(inputText)
        }
        return nil
    }
    
    @ViewBuilder
    func globalSearchResultOrEmptyView() -> some View {
        if let result = getCurrentGlobalSearchResult() {
            Section {
                switch result {
                case .profiles(let globalProfiles):
                    ForEach(globalProfiles, id: \.self) { profile in
                        selectableGlobalProfileView(profile: profile)
                    }
                case .fullAddress(let address):
                    selectableGlobalAddressRowView(address)
                }
            } header: {
                sectionHeaderViewWith(title: String.Constants.results.localized())
            }
        } else {
            HomeExploreEmptySearchResultView()
        }
    }
    
    @ViewBuilder
    func selectableGlobalAddressRowView(_ address: HexAddress) -> some View {
        selectableRowView({
            UDListItemView(title: address.walletAddressTruncated,
                           titleColor: .foregroundDefault,
                           subtitle: nil,
                           subtitleStyle: .default,
                           value: nil,
                           imageType: .image(.walletExternalIcon),
                           imageStyle: .centred(offset: .init(8),
                                                foreground: .foregroundDefault,
                                                background: .backgroundMuted2,
                                                bordered: true),
                           rightViewStyle: nil)
        }, callback: {
            logAnalytic(event: .searchWalletAddressPressed, parameters: [.wallet : address])
            viewModel.handleAction(.globalWalletAddressSelected(address))
        })
    }
    
    @ViewBuilder
    func selectableGlobalProfileView(profile: SearchDomainProfile) -> some View {
        selectableRowView {
            DomainSearchResultProfileRowView(profile: profile)
        } callback: {
            logAnalytic(event: .searchProfilePressed, parameters: [.domainName : profile.name])
            viewModel.handleAction(.globalProfileSelected(profile))
        }
    }
    
    @ViewBuilder
    func sectionHeaderViewWith(title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.currentFont(size: 14, weight: .medium))
                .foregroundStyle(Color.foregroundSecondary)
            HomeExploreSeparatorView()
        }
    }
    
    @ViewBuilder
    func selectableRowView(@ViewBuilder _ content: @escaping ()->(some View),
                           callback: @escaping EmptyCallback) -> some View {
        UDCollectionListRowButton {
            content()
            .padding(.init(horizontal: 8))
        } callback: {
            callback()
        }
        .padding(.init(horizontal: -8))
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSelectReceiverView {
    var isSearchingInProgress: Bool {
        !inputText.isEmpty
    }
    
    func searchForGlobalProfiles() {
        guard isSearchingInProgress else {
            globalProfiles = []
            return
        }
        
        isLoadingGlobalProfiles = true
        Task {
            do {
                self.globalProfiles = try await searchService.searchForGlobalProfilesExcludingUsers(with: inputText,
                                                                                                    walletsDataService: walletsDataService)
            }
            isLoadingGlobalProfiles = false
        }
    }
}

#Preview {
    NavigationStack {
        SendCryptoAssetSelectReceiverView()
    }
    .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
