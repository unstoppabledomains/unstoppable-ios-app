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
    }
    
}

// MARK: - Private methods
private extension HomeWalletsDomainsSectionView {
    @ViewBuilder
    func subdomainsSectionHeader() -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            isSubdomainsVisible.toggle()
        } label: {
            HStack {
                Text("Subdomains")
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
                
                if subdomains.count > minNumOfVisibleSubdomains {
                    HStack(spacing: 8) {
                        Text(String(subdomains.count))
                            .font(.currentFont(size: 16))
                        Image(uiImage: isSubdomainsVisible ? .chevronUp : .chevronDown)
                            .resizable()
                            .squareFrame(20)
                    }
                    .foregroundStyle(Color.foregroundSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    var numberOfVisibleSubdomains: Int {
        let numberOfSubdomains = subdomains.count
        
        return isSubdomainsVisible ? numberOfSubdomains : min(numberOfSubdomains, minNumOfVisibleSubdomains) //Take no more then minNumOfVisibleSubdomains Subdomains
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
