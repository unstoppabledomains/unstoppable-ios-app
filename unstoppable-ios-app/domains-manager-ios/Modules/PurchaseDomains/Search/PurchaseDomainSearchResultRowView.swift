//
//  PurchaseDomainSearchResultRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2024.
//

import SwiftUI

struct PurchaseDomainSearchResultRowView: View {
    
    @EnvironmentObject private var localCart: PurchaseDomains.LocalCart
    let domain: DomainToPurchase
    let mode: RowMode
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                domain.tldCategory.icon
                    .squareFrame(24)
                    .foregroundStyle(Color.foregroundSecondary)
                VStack(alignment: .leading, spacing: 0) {
                    Text(domain.name)
                        .textAttributes(color: .foregroundDefault,
                                        fontSize: 16,
                                        fontWeight: .medium)
                        .frame(height: 24)
                    Text(formatCartPrice(domain.price))
                        .textAttributes(color: .foregroundSecondary,
                                        fontSize: 14)
                        .frame(height: 20)
                }
            }
            Spacer()
            cartIconView()
                .squareFrame(24)
        }
        .frame(minHeight: UDListItemView.height)
    }
}

// MARK: - Private methods
private extension PurchaseDomainSearchResultRowView {
    @ViewBuilder
    func cartIconView() -> some View {
        switch mode {
        case .list:
            if localCart.isDomainInCart(domain) {
                Image.checkCircle
                    .resizable()
                    .foregroundStyle(Color.foregroundSuccess)
            } else {
                Image.addToCartIcon
                    .resizable()
                    .foregroundStyle(Color.foregroundAccent)
            }
        case .cart:
            Image.trashIcon
                .resizable()
                .foregroundStyle(Color.foregroundMuted)
        }
    }
}

extension PurchaseDomainSearchResultRowView {
    enum RowMode {
        case list
        case cart
    }
}

#Preview {
    PurchaseDomainSearchResultRowView(domain: .init(name: "oleg.eth",
                                                    price: 199,
                                                    metadata: nil,
                                                    isAbleToPurchase: true),
                                      mode: .list)
    .environmentObject(PurchaseDomains.LocalCart())
}
