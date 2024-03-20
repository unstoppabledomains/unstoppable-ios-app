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
    @Environment(\.presentationMode) private var presentationMode
    
    @EnvironmentObject var viewModel: SendCryptoAssetViewModel
    var analyticsName: Analytics.ViewName { .sendCryptoReceiverSelection }


    @State private var userWallets: [WalletEntity] = []
    @State private var followingList: [DomainName] = []
    @State private var inputText: String = ""
    @State private var socialRelationshipDetailsPublisher: AnyCancellable?
    
    var body: some View {
        List {
            inputFieldView()
                .listRowSeparator(.hidden)
            scanQRView()
                .listRowSeparator(.hidden)
            userWalletsSection()
                .listRowSeparator(.hidden)
            followingsSection()
                .listRowSeparator(.hidden)
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
    }
}

// MARK: - Private methods
private extension SendCryptoAssetSelectReceiverView {
    @ViewBuilder
    func closeButton() -> some View {
        CloseButtonView {
            logButtonPressedAnalyticEvents(button: .close)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    @ViewBuilder
    func inputFieldView() -> some View {
        UDTextFieldView(text: $inputText,
                        placeholder: String.Constants.domainOrAddress.localized(),
                        hint: String.Constants.to.localized(),
                        rightViewType: .paste,
                        rightViewMode: .always,
                        autocapitalization: .never,
                        autocorrectionDisabled: true)
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
            viewModel.handleAction(.scanQRSelected)
        }
    }
    
    @ViewBuilder
    func userWalletsSection() -> some View {
        if !userWallets.isEmpty {
            Section {
                ForEach(userWallets) { wallet in
                    selectableUserWalletView(wallet: wallet)
                }
            } header: {
                sectionHeaderViewWith(title: String.Constants.yourWallets.localized())
            }
        }
    }
    
    @ViewBuilder
    func selectableUserWalletView(wallet: WalletEntity) -> some View {
        selectableRowView {
            SendCryptoAssetSelectReceiverWalletRowView(wallet: wallet)
        } callback: {
            viewModel.handleAction(.userWalletSelected(wallet))
        }
    }
    
    @ViewBuilder
    func followingsSection() -> some View {
        if !followingList.isEmpty {
            Section {
                ForEach(followingList, id: \.self) { following in
                    selectableFollowingView(following: following)
                }
            } header: {
                sectionHeaderViewWith(title: String.Constants.following.localized())
            }
        }
    }
    
    @ViewBuilder
    func selectableFollowingView(following: DomainName) -> some View {
        selectableRowView {
            SendCryptoAssetSelectReceiverFollowingRowView(domainName: following)
        } callback: {
            viewModel.handleAction(.followingDomainSelected(following))
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

#Preview {
    SendCryptoAssetSelectReceiverView()
        .environmentObject(MockEntitiesFabric.SendCrypto.mockViewModel())
}
