//
//  HomeWalletsDomainsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletsDomainsSectionView: View {
    
    let domains: [DomainDisplayInfo]
    let subdomains: [DomainDisplayInfo]
    let domainSelectedCallback: (DomainDisplayInfo)->()
    @Binding var isSubdomainsVisible: Bool
    private let minNumOfVisibleSubdomains = 2

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVStack {
            gridWithDomains(domains)
            if !subdomains.isEmpty {
                subdomainsSectionHeader()
                    .padding(.vertical)
                gridWithDomains(Array(subdomains.prefix(numberOfVisibleSubdomains)))
            }
        }
        .withoutAnimation()
    }
    
}

// MARK: - Private methods
private extension HomeWalletsDomainsSectionView {
    @ViewBuilder
    func subdomainsSectionHeader() -> some View {
        HomeWalletExpandableSectionHeaderView(title: String.Constants.subdomains.localized(),
                                              isExpandable: subdomains.count > minNumOfVisibleSubdomains,
                                              numberOfItemsInSection: subdomains.count,
                                              isExpanded: isSubdomainsVisible,
                                              actionCallback: {
            isSubdomainsVisible.toggle()
        })
    }
    
    var numberOfVisibleSubdomains: Int {
        let numberOfSubdomains = subdomains.count
        
        return isSubdomainsVisible ? numberOfSubdomains : min(numberOfSubdomains, minNumOfVisibleSubdomains) //Take no more than minNumOfVisibleSubdomains Subdomains
    }
    
    @ViewBuilder
    func gridWithDomains(_ domains: [DomainDisplayInfo]) -> some View {
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
    HomeWalletsDomainsSectionView(domains: [],
                                  subdomains: [],
                                  domainSelectedCallback: { _ in }, isSubdomainsVisible: .constant(true))
}
