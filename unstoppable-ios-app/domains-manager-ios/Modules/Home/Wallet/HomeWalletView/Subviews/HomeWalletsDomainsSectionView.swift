//
//  HomeWalletsDomainsSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.01.2024.
//

import SwiftUI

struct HomeWalletsDomainsSectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    
    @Binding var domainsData: HomeWalletView.DomainsSectionData
    let domainSelectedCallback: (DomainDisplayInfo)->()
    let buyDomainCallback: EmptyCallback
    private let minNumOfVisibleSubdomains = 2

    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        domainsGroupsView()
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
    var domainsGroups: [DomainsTLDGroup] { domainsData.domainsGroups }
    var subdomains: [DomainDisplayInfo] { domainsData.subdomains }
    var isSubdomainsVisible: Bool { domainsData.isSubdomainsVisible }
    var domainsTLDsExpandedList: Set<String> { domainsData.domainsTLDsExpandedList }
    
    
    @ViewBuilder
    func domainsGroupSectionHeader(_ domainsGroup: DomainsTLDGroup) -> some View {
        HomeWalletExpandableSectionHeaderView(title: ".\(domainsGroup.tld)",
                                              isExpandable: domainsGroup.numberOfDomains > minNumOfVisibleSubdomains,
                                              numberOfItemsInSection: domainsGroup.numberOfDomains,
                                              isExpanded: domainsTLDsExpandedList.contains(domainsGroup.tld),
                                              actionCallback: {
            let tld = domainsGroup.tld
            let isExpanded = domainsTLDsExpandedList.contains(tld)
            logButtonPressedAnalyticEvents(button: .domainsSectionHeader,
                                           parameters: [.expand : String(!isExpanded),
                                                        .tld : tld,
                                                        .numberOfItemsInSection: String(domainsGroup.numberOfDomains)])
            if isExpanded {
                domainsData.domainsTLDsExpandedList.remove(tld)
            } else {
                domainsData.domainsTLDsExpandedList.insert(tld)
            }
        })
    }
    
    func numberOfDomainsVisible(in domainsGroup: DomainsTLDGroup) -> Int {
        let numberOfNFTs = domainsGroup.numberOfDomains
        return domainsTLDsExpandedList.contains(domainsGroup.tld) ? numberOfNFTs : min(numberOfNFTs, minNumOfVisibleSubdomains) //Take no more then 2 domains
    }
    
    @ViewBuilder
    func subdomainsSectionHeader() -> some View {
        HomeWalletExpandableSectionHeaderView(title: String.Constants.subdomains.localized(),
                                              isExpandable: subdomains.count > minNumOfVisibleSubdomains,
                                              numberOfItemsInSection: subdomains.count,
                                              isExpanded: isSubdomainsVisible,
                                              actionCallback: {
            domainsData.isSubdomainsVisible.toggle()
            logButtonPressedAnalyticEvents(button: .subdomainsSectionHeader,
                                           parameters: [.expand : String(!isSubdomainsVisible),
                                                        .numberOfItemsInSection: String(subdomains.count)])
        })
    }
    
    var numberOfVisibleSubdomains: Int {
        let numberOfSubdomains = subdomains.count
        
        return isSubdomainsVisible ? numberOfSubdomains : min(numberOfSubdomains, minNumOfVisibleSubdomains) //Take no more than minNumOfVisibleSubdomains Subdomains
    }
    
    @ViewBuilder
    func domainsGroupsView() -> some View {
        if domainsGroups.isEmpty,
           !domainsData.isSearching {
            buyDomainView()
        } else {
            ForEach(domainsGroups) { domainsGroup in
                Section {
                    gridWithDomains(Array(domainsGroup.domains.prefix(numberOfDomainsVisible(in: domainsGroup))))
                } header: {
                    domainsGroupSectionHeader(domainsGroup)
                }
            }
        }
    }
    
    @ViewBuilder
    func gridWithDomains(_ domains: [DomainDisplayInfo]) -> some View {
        ListVGrid(data: domains, 
                  verticalSpacing: 16,
                  horizontalSpacing: 16) { domain in
            Button {
                UDVibration.buttonTap.vibrate()
                logButtonPressedAnalyticEvents(button: .domainTile,
                                               parameters: [.domainName : domain.name])
                domainSelectedCallback(domain)
            } label: {
                HomeWalletDomainCellView(domain: domain)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    func buyDomainView() -> some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            Button {
                logButtonPressedAnalyticEvents(button: .buyDomainTile)
                UDVibration.buttonTap.vibrate()
                buyDomainCallback()
            } label: {
                ZStack {
                    Color.gray.opacity(0.2)
                    VStack(spacing: 12) {
                        Image.plusIconNav
                            .resizable()
                            .squareFrame(30)
                        Text(String.Constants.buyDomain.localized())
                    }
                    .foregroundStyle(Color.foregroundSecondary)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .aspectRatio(1, contentMode: .fit)
                .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    HomeWalletsDomainsSectionView(domainsData: .constant(.init(domainsGroups: [.init(domains: [.init(name: "oleg.x", ownerWallet: "123", isSetForRR: false)],
                                                                                     tld: "x")],
                                                               subdomains: [.init(name: "oleg.oleg.x", ownerWallet: "123", isSetForRR: false)])),
                                  domainSelectedCallback: { _ in },
                                  buyDomainCallback: { })
    .frame(width: 390)
    .padding()
}
