//
//  UICollectionViewLayout.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

extension UICollectionViewLayout {
    
    static func fullSizeLayout() -> UICollectionViewLayout {
        let config = UICollectionViewCompositionalLayoutConfiguration()
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                 heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = .zero
            
            let containerGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .fractionalHeight(1)),
                subitems: [item])
            let section = NSCollectionLayoutSection(group: containerGroup)
            section.contentInsets = .zero
            
            return section
            
        }, configuration: config)
        
        return layout
    }
    
}

extension NSCollectionLayoutSection {
    static func listItemSection(height: CGFloat = BaseListCollectionViewCell.height) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                             heightDimension: .fractionalHeight(1.0)))
        item.contentInsets = .zero
        let containerGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(height)),
            subitems: [item])
        let section = NSCollectionLayoutSection(group: containerGroup)
        
        return section
    }
    
    static func flexibleListItemSection(height: CGFloat = BaseListCollectionViewCell.height) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                             heightDimension: .estimated(height)))
        item.contentInsets = .zero
        let containerGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(height)),
            subitems: [item])
        let section = NSCollectionLayoutSection(group: containerGroup)
        
        return section
    }
    
    static func multipleListItemSection(height: CGFloat = BaseListCollectionViewCell.height,
                                        numberOfItems: Int,
                                        contentInset: CGFloat = 8) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                             heightDimension: .fractionalHeight(1.0)))
        let containerGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .absolute(height)),
            subitem: item, count: numberOfItems)
        containerGroup.interItemSpacing = .fixed(contentInset)
        let section = NSCollectionLayoutSection(group: containerGroup)
        section.interGroupSpacing = contentInset

        return section
    }
    
}
