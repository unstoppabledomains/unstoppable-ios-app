//
//  ReverseResolutionSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

struct ReverseResolutionSelectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.udWalletsService) private var udWalletsService
    @Environment(\.walletsDataService) private var walletsDataService
    @Environment(\.presentationMode) private var presentationMode

    @EnvironmentObject var tabRouter: HomeTabRouter
    @StateObject private var paymentHandler = SwiftUIViewPaymentHandler()
    var analyticsName: Analytics.ViewName { .setupReverseResolution }
    
    @State var wallet: WalletEntity
    
    @State private var error: Error?
    @State private var isSettingRRDomain = false
    @State private var domains: [DomainDisplayInfo] = []
    @State private var selectedDomain: DomainDisplayInfo?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        headerView()
                        domainsListView()
                        buyDomainView()
                    }
                }
            }
            .background(Color.backgroundDefault)
            .displayError($error, dismissCallback: dismiss)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView {
                        
                    }
                    .opacity(0)
                }
                ToolbarItem(placement: .bottomBar) {
                    confirmView()
                }
            })
            .onAppear(perform: { setAvailableDomains() })
            .onReceive(walletsDataService.walletsPublisher.receive(on: DispatchQueue.main)) { wallets in
                guard let wallet = wallets.first(where: { $0.address == self.wallet.address }),
                      wallet.rrDomain == nil,
                      wallet.isReverseResolutionChangeAllowed() else {
                    dismiss()
                    return
                }
                self.wallet = wallet
                setAvailableDomains()
            }
        }
    }
}

// MARK: - Private methods
private extension ReverseResolutionSelectionView {
    func setAvailableDomains() {
        domains = wallet.domains.availableForRRItems()
    }
    
    @ViewBuilder
    func headerView() -> some View {
        VStack {
            Image.crownIcon
                .resizable()
                .squareFrame(48)
                .foregroundStyle(Color.foregroundMuted)
            AttributedText(attributesList: .init(text: String.Constants.selectPrimaryDomainTitle.localized(wallet.displayName),
                                                 font: .currentFont(withSize: 32, weight: .bold),
                                                 textColor: .foregroundDefault,
                                                 alignment: .center),
                           width: UIScreen.main.bounds.width - 32,
                           updatedAttributesList: [.init(text: wallet.displayName,
                                                         textColor: .foregroundSecondary)])
            AttributedText(attributesList: .init(text: String.Constants.selectPrimaryDomainSubtitle.localized(wallet.address.walletAddressTruncated, wallet.displayName),
                                                 font: .currentFont(withSize: 16),
                                                 textColor: .foregroundSecondary,
                                                 alignment: .center),
                           width: UIScreen.main.bounds.width - 32,
                           updatedAttributesList: [.init(text: wallet.displayName,
                                                         font: .currentFont(withSize: 16, weight: .medium),
                                                         textColor: .foregroundDefault),
                                                   .init(text: wallet.address.walletAddressTruncated,
                                                         font: .currentFont(withSize: 16, weight: .medium),
                                                         textColor: .foregroundDefault)])
        }
        .padding()
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack(spacing: 0) {
                ForEach(domains) { domain in
                    domainsRowView(domain)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
    
    @ViewBuilder
    func domainsRowView(_ domain: DomainDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            ReverseResolutionSelectionRowView(domain: domain,
                                              isSelected: domain.name == selectedDomain?.name)
        }, callback: {
            UDVibration.buttonTap.vibrate()
            selectedDomain = domain
        })
    }
    
    @ViewBuilder
    func buyDomainView() -> some View {
        UDCollectionSectionBackgroundView {
            UDCollectionListRowButton(content: {
                UDListItemView(title: String.Constants.buyNewDomain.localized(),
                               titleColor: .foregroundAccent,
                               imageType: .image(.plusIconNav),
                               imageStyle: .clearImage(foreground: .foregroundAccent))
                .padding(EdgeInsets(top: -12, leading: 0, bottom: -12, trailing: 0))
            }, callback: {
                UDVibration.buttonTap.vibrate()
                tabRouter.runPurchaseFlow()
            })
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
    }
    
    @ViewBuilder
    func confirmView() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(),
                     icon: nil,
                     style: .large(.raisedPrimary),
                     isLoading: isSettingRRDomain) {
            logButtonPressedAnalyticEvents(button: .confirm, parameters: [.value : selectedDomain?.name ?? ""])
            setSelectedDomainAsRR()
        }
                     .disabled(selectedDomain == nil)
                     .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
                     .allowsHitTesting(!isSettingRRDomain)
    }
    
    func setSelectedDomainAsRR() {
        Task {
            isSettingRRDomain = true
            do {
                guard let selectedDomain else { return }
                let domain = try await appContext.dataAggregatorService.getDomainWith(name: selectedDomain.name)
                
                try await udWalletsService.setReverseResolution(to: domain,
                                                                paymentConfirmationDelegate: paymentHandler)
                dismiss()
            } catch {
                self.error = error
            }
            isSettingRRDomain = false
        }
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ReverseResolutionSelectionView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
