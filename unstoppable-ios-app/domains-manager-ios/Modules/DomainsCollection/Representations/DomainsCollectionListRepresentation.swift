//
//  DomainsCollectionListRepresentation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class DomainsCollectionListRepresentation {
    var domains: [DomainItem]
    var reverseResolutionDomains: [DomainItem]
    var isSearchActive: Bool

    init(domains: [DomainItem],
         reverseResolutionDomains: [DomainItem],
         isSearchActive: Bool) {
        self.domains = domains
        self.reverseResolutionDomains = reverseResolutionDomains
        self.isSearchActive = isSearchActive
    }
}

extension DomainsCollectionListRepresentation: DomainsCollectionRepresentation {
    var isScrollEnabled: Bool { true }
    
    func layout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = NSCollectionLayoutSection.flexibleListItemSection(height: 72)
            guard let self = self else { return section }
            let snapshot = self.snapshot()
            
            if snapshot.numberOfSections > sectionIndex,
                snapshot.sectionIdentifiers[sectionIndex] == .search {
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(DomainsListSearchHeaderView.Height))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                section.boundarySupplementaryItems = [header]
            } else if snapshot.numberOfSections > sectionIndex,
                      snapshot.sectionIdentifiers[sectionIndex] == .searchEmptyState {
                
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .zero
                
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .fractionalHeight(1)),
                    subitems: [item])
                let section = NSCollectionLayoutSection(group: containerGroup)
                section.contentInsets = .zero
                section.contentInsets.bottom = -368 // Keyboard height inset

                return section
            } else {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                let inset: CGFloat = DomainsListSearchHeaderView.Height
                section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                leading: spacing + 1,
                                                                bottom: 1,
                                                                trailing: spacing + 1)
                if self.isSearchActive,
                   sectionIndex == 0 {
                    background.contentInsets.top = inset
                    section.contentInsets.top += inset
                }
                
                section.decorationItems = [background]
            }
            
            return section
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)

        return layout
    }
    
    func snapshot() -> DomainsCollectionSnapshot {
        var snapshot = DomainsCollectionSnapshot()
        
        if domains.isEmpty,
           isSearchActive {
            snapshot.appendSections([.searchEmptyState])
            snapshot.appendItems([.searchEmptyState])
            return snapshot
        }
        
        if !isSearchActive {
            snapshot.appendSections([.search]) //  For search bar
        }
        
        var primaryDomain: DomainItem?
        var otherDomains: [DomainItem] = []
        var mintingDomains: [DomainItem] = []
        
        for domain in domains {
            if domain.isPrimary == true {
                primaryDomain = domain
            } else if domain.isMinting {
                mintingDomains.append(domain)
            } else {
                otherDomains.append(domain)
            }
        }
                
        if let primaryDomain = primaryDomain {
            snapshot.appendSections([.primary]) // For primary domain
            snapshot.appendItems([.domainListItem(primaryDomain,
                                                  isUpdatingRecords: primaryDomain.isUpdatingRecords,
                                                  isSelectable: true,
                                                  isReverseResolution: false)])
        }
        
        if !mintingDomains.isEmpty {
            snapshot.appendSections([.minting])
            snapshot.appendItems([.domainsMintingInProgress(domainsCount: mintingDomains.count)])
        }
        
        if !otherDomains.isEmpty {
            snapshot.appendSections([.other]) // For other domains
            snapshot.appendItems(otherDomains.map({
                DomainsCollectionViewController.Item.domainListItem($0,
                                                                    isUpdatingRecords: $0.isUpdatingRecords,
                                                                    isSelectable: true,
                                                                    isReverseResolution: false)
                
            }))
        }

        return snapshot
    }
}
