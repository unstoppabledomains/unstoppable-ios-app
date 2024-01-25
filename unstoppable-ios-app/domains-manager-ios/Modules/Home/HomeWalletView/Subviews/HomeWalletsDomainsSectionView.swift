//
//  HomeWalletsDomainsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletsDomainsSectionView: View {
    
    let domains: [DomainDisplayInfo]
    let domainSelectedCallback: (DomainDisplayInfo)->()

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(domains, id: \.name) { domain in
                Button {
                    UDVibration.buttonTap.vibrate()
                    domainSelectedCallback(domain)
                } label: {
                    HomeWalletDomainCellView(domain: domain)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    HomeWalletsDomainsSectionView(domains: [], domainSelectedCallback: { _ in })
}
