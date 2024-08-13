//
//  PurchaseDomainsCompletedView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2024.
//

import SwiftUI

struct PurchaseDomainsCompletedView: View {
    
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel

    let purchasedDomainsData: PurchaseDomains.PurchasedDomainsData
    @State private var offset: CGPoint = .zero
    @State private var confettiCounter = 0
    
    var body: some View {
        VStack {
            OffsetObservingScrollView(offset: $offset) {
                headerView()
                purchasedDomainsList()
            }
            
            doneButtonView()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // To keep showing top bar when scrolling
            ToolbarItem(placement: .topBarTrailing) {
                Color.clear
            }
        }
        .udConfetti(counter: $confettiCounter)
        .onAppear {
            confettiCounter += 1
        }
    }
 
}

// MARK: - Private methods
private extension PurchaseDomainsCompletedView {
    var navTitle: String {
        if offset.y > 144 {
            return String.Constants.youAreAllDoneTitle.localized()
        }
        return ""
    }
    
    @ViewBuilder
    func headerView() -> some View {
        LazyVStack(spacing: 24) {
            Image.checkCircle
                .resizable()
                .squareFrame(56)
                .foregroundStyle(Color.foregroundAccent)
            LazyVStack(spacing: 16) {
                Text(String.Constants.youAreAllDoneTitle.localized())
                    .textAttributes(color: .foregroundDefault,
                                    fontSize: 32,
                                    fontWeight: .bold)
                    .onDisappear {
                        print("title disappeared")
                    }
                orderInfoView()
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func orderInfoView() -> some View {
        AttributedText(attributesList: .init(text: String.Constants.domainsPurchasedSummaryMessage.localized(orderTotal, mintWalletDescription),
                                             font: .currentFont(withSize: 16, weight: .regular),
                                             textColor: .foregroundSecondary,
                                             alignment: .center),
                       updatedAttributesList: [.init(text: mintWalletName ?? walletAddress,
                                                     font: .currentFont(withSize: 16, weight: .medium),
                                                     textColor: .foregroundDefault)])
    }
    
    var wallet: WalletEntity {
        purchasedDomainsData.wallet
    }
    
    var orderTotal: String {
        purchasedDomainsData.totalSum
    }
    
    var walletAddress: String {
        wallet.address.walletAddressTruncated
    }
    
    var mintWalletDescription: String {
        if let mintWalletName {
            return "\(mintWalletName) (\(walletAddress))"
        }
        return walletAddress
    }
    
    var mintWalletName: String? {
        if wallet.displayInfo.isNameSet {
            return wallet.displayInfo.name
        }
        return nil
    }
    
    @ViewBuilder
    func purchasedDomainsList() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack(alignment: .center, spacing: 4) {
                ForEach(purchasedDomainsData.domains) { domain in
                    domainRowView(domain)
                }
            }
        }
        .padding(.top, 32)
    }
    
    @ViewBuilder
    func domainRowView(_ domain: DomainToPurchase) -> some View {
        HStack(spacing: 16) {
            domain.tldCategory.icon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundSecondary)
            
            Text(domain.name)
                .textAttributes(color: .foregroundDefault,
                                fontSize: 16,
                                fontWeight: .medium)
                .lineLimit(1)
            Spacer()
        }
        .frame(height: 64)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    func doneButtonView() -> some View {
        UDButtonView(text: String.Constants.goToDomains.localized(),
                     style: .large(.raisedPrimary)) {
            viewModel.handleAction(.goToDomains)
        }
        .padding(.horizontal, 16)
    }
 }

#Preview {
    let router = MockEntitiesFabric.Home.createHomeTabRouter()
    let viewModel = PurchaseDomainsViewModel(router: router)
    let domains = MockEntitiesFabric.Domains.mockDomainsToPurchase()
    let sum = formatCartPrice(domains.reduce(0, { $0 + $1.price }))
    let wallet = MockEntitiesFabric.Wallet.mockEntities().randomElement()!

    return NavigationStack {
        PurchaseDomainsCompletedView(purchasedDomainsData: .init(domains: domains,
                                                                 totalSum: sum,
                                                                 wallet: wallet))
        .environmentObject(router)
        .environmentObject(viewModel)
    }
}
