//
//  DomainsCollectionEmptyListRepresentation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.07.2022.
//

import UIKit

final class DomainsCollectionEmptyListRepresentation {
    
  
}

extension DomainsCollectionEmptyListRepresentation: DomainsCollectionRepresentation {
    var isScrollEnabled: Bool { false }
    
    func layout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = NSCollectionLayoutSection.flexibleListItemSection(height: 100)
                        
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                            leading: spacing + 1,
                                                            bottom: 1,
                                                            trailing: spacing + 1)
            if sectionIndex != 0 {
                section.decorationItems = [background]
            }
            
            
            return section
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
    
    func snapshot() -> DomainsCollectionSnapshot {
        var snapshot = DomainsCollectionSnapshot()
        
        snapshot.appendSections([.emptyTopInfo])
        snapshot.appendItems([.emptyTopInfo])
        snapshot.appendSections([.emptyList(item: .mintDomains)])
        snapshot.appendItems([.emptyList(item: .mintDomains)])
        snapshot.appendSections([.emptyList(item: .manageDomains)])
        snapshot.appendItems([.emptyList(item: .manageDomains)])
        
        return snapshot
    }
}


