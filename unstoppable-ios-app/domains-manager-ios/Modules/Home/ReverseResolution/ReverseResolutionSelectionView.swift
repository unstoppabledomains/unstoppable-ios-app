//
//  ReverseResolutionSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.01.2024.
//

import SwiftUI

struct ReverseResolutionSelectionView: View, ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .setupReverseResolution }
    
    let wallet: WalletEntity
    
    @State private var domains: [DomainDisplayInfo] = []
    @State private var selectedDomain: DomainDisplayInfo?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack {
                        headerView()
                        domainsListView()
                    }
                }
                confirmView()
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigation) {
                    CloseButtonView {
                        
                    }
                }
            })
            .onAppear(perform: {
                domains = wallet.domains.availableForRRItems()
            })
        }
    }
}

// MARK: - Private methods
private extension ReverseResolutionSelectionView {
    @ViewBuilder
    func headerView() -> some View {
        VStack {
            Image.appleIcon
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
            LazyVStack(alignment: .center, spacing: 0) {
                ForEach(domains) { domain in
                    domainsRowView(domain)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
        .padding()
    }
    
    @ViewBuilder
    func domainsRowView(_ domain: DomainDisplayInfo) -> some View {
        UDCollectionListRowButton(content: {
            ReverseResolutionSelectionRowView(domain: domain,
                                              isSelected: domain.name == selectedDomain?.name)
            .padding(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        }, callback: {
            UDVibration.buttonTap.vibrate()
            selectedDomain = domain
        })
    }
    
    @ViewBuilder
    func confirmView() -> some View {
        UDButtonView(text: String.Constants.confirm.localized(), icon: nil, style: .large(.raisedPrimary)) {
            logButtonPressedAnalyticEvents(button: .confirm, parameters: [.value : selectedDomain?.name ?? ""])
        }
        .disabled(selectedDomain == nil)
        .padding()
    }
}

#Preview {
    ReverseResolutionSelectionView(wallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
