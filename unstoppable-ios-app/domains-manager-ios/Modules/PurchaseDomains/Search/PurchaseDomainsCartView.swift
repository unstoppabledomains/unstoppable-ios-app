//
//  PurchaseDomainsCartView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2024.
//

import SwiftUI

struct PurchaseDomainsCartView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: PurchaseDomainsViewModel

    var body: some View {
        if viewModel.localCart.domains.isEmpty {
            emptyView()
                .presentationDetents([.height(238)])
        } else {
            cartContentView()
                .modifier(PurchaseDomainsCheckoutButton())
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Private methods
private extension PurchaseDomainsCartView {
    @ViewBuilder
    func emptyView() -> some View {
        VStack(spacing: 16) {
            DismissIndicatorView()
                .padding(.top, 16)
                .padding(.bottom, 4)
            
            Image.cartFillIcon
                .resizable()
                .squareFrame(48)
            VStack(spacing: 8) {
                Text(String.Constants.buyDomainsCartEmptyTitle.localized())
                    .font(.currentFont(size: 22, weight: .bold))
                    .frame(height: 28)
                Text(String.Constants.buyDomainsCartEmptySubtitle.localized())
                    .font(.currentFont(size: 16))
                    .frame(height: 24)
            }
            
            
            UDButtonView(text: String.Constants.searchDomains.localized(),
                         style: .medium(.ghostPrimary)) {
                dismiss()
            }
            Spacer()
        }
        .foregroundStyle(Color.foregroundSecondary)
        .padding(.horizontal, 16)
        .backgroundStyle(Color.clear)
    }
    
    @ViewBuilder
    func cartContentView() -> some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView()
                domainsListView()
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 36)
    }
    
    
    @ViewBuilder
    func headerView() -> some View {
        HStack(spacing: 4) {
            Text(String.Constants.buyDomainsCartTitle.localized(viewModel.localCart.domains.count))
                .textAttributes(color: .foregroundDefault,
                                fontSize: 22,
                                fontWeight: .bold)
            Spacer()
            Button {
                UDVibration.buttonTap.vibrate()
                viewModel.localCart.clearCart()
            } label: {
                Text(String.Constants.clear.localized())
                    .textAttributes(color: .foregroundSecondary,
                                    fontSize: 16,
                                    fontWeight: .medium)
                    .underline()
            }
        }
    }
    
    @ViewBuilder
    func domainsListView() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.localCart.domains) { domain in
                    domainListRow(domain)
                        .udListItemInCollectionButtonPadding()
                }
            }
        }
    }
    
    @ViewBuilder
    func domainListRow(_ domain: DomainToPurchase) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            withAnimation {
                viewModel.localCart.removeDomain(domain)
            }
        } label: {
            PurchaseDomainsSearchResultRowView(domain: domain,
                                              mode: .cart)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PurchaseDomainsCartView()
//        .environmentObject(PurchaseDomains.LocalCart())
}
