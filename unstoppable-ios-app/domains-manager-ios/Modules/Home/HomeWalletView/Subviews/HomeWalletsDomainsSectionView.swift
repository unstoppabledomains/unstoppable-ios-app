//
//  HomeWalletsDomainsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletsDomainsSectionView: View {
    
    let domainsGroups: [HomeWalletView.DomainsGroup]
    let subdomains: [DomainDisplayInfo]
    let domainSelectedCallback: (DomainDisplayInfo)->()
    @Binding var isSubdomainsVisible: Bool
    @Binding var domainsTLDsExpandedList: Set<String>
    private let minNumOfVisibleSubdomains = 2

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ForEach(domainsGroups) { domainsGroup in
            Section {
                gridWithDomains(Array(domainsGroup.domains.prefix(numberOfDomainsVisible(in: domainsGroup))))
            } header: {
                domainsGroupSectionHeader(domainsGroup)
            }
        }
        .withoutAnimation()
        if !subdomains.isEmpty {
            Line()
                .stroke(lineWidth: 1)
                .foregroundStyle(Color.foregroundSecondary)
                .offset(y: 36)
            Section {
                gridWithDomains(Array(subdomains.prefix(numberOfVisibleSubdomains)))
            } header: {
                subdomainsSectionHeader()
            }
        }
    }
    
}

// MARK: - Private methods
private extension HomeWalletsDomainsSectionView {
    @ViewBuilder
    func domainsGroupSectionHeader(_ domainsGroup: HomeWalletView.DomainsGroup) -> some View {
        HomeWalletExpandableSectionHeaderView(title: ".\(domainsGroup.tld)",
                                              isExpandable: domainsGroup.domains.count > minNumOfVisibleSubdomains,
                                              numberOfItemsInSection: domainsGroup.domains.count,
                                              isExpanded: domainsTLDsExpandedList.contains(domainsGroup.tld),
                                              actionCallback: {
            let tld = domainsGroup.tld
            if domainsTLDsExpandedList.contains(tld) {
                domainsTLDsExpandedList.remove(tld)
            } else {
                domainsTLDsExpandedList.insert(tld)
            }
        })
    }
    
    func numberOfDomainsVisible(in domainsGroup: HomeWalletView.DomainsGroup) -> Int {
        let numberOfNFTs = domainsGroup.domains.count
        return domainsTLDsExpandedList.contains(domainsGroup.tld) ? numberOfNFTs : min(numberOfNFTs, minNumOfVisibleSubdomains) //Take no more then 2 domains
    }
    
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
//        .padding(EdgeInsets(top: -14, leading: 0, bottom: -38, trailing: 0))
    }
}

#Preview {
    HomeWalletsDomainsSectionView(domainsGroups: [],
                                  subdomains: [],
                                  domainSelectedCallback: { _ in }, 
                                  isSubdomainsVisible: .constant(true),
                                  domainsTLDsExpandedList: .constant([]))
}
