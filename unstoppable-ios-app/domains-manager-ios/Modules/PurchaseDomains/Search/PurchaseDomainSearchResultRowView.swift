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
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                domainIconView(domain)
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSuccess)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .background(Color.backgroundSuccess)
                    .clipShape(Circle())
                Text(domain.name)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
            }
            Spacer()
            Text(formatCartPrice(domain.price))
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
            Image.chevronRight
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundMuted)
        }
        .frame(minHeight: UDListItemView.height)
    }
}

// MARK: - Private methods
private extension PurchaseDomainSearchResultRowView {
    @ViewBuilder
    func domainIconView(_ domain: DomainToPurchase) -> some View {
        if localCart.isDomainInCart(domain) {
            Image.check
                .resizable()
        } else {
            Image(systemName: "cart.fill.badge.plus")
                .resizable()
        }
    }
}

#Preview {
    PurchaseDomainSearchResultRowView(domain: .init(name: "oleg.x",
                                                    price: 199,
                                                    metadata: nil,
                                                    isAbleToPurchase: true))
}
