//
//  DomainsCollectionUICache.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.12.2022.
//

import UIKit

@MainActor
final class DomainsCollectionUICache {
    
    static let shared = DomainsCollectionUICache()

    // Constants
    static let nominalCardWidth: CGFloat = 342
    private let nominalCardAspectRatio: CGFloat = 416 / DomainsCollectionUICache.nominalCardWidth
    
    // Properties
    private var collectionViewHeight: CGFloat = 0
    private var collectionViewYInContainer: CGFloat = 0
    
    // Cache
    private var cardFractionalHeightCache: [CGFloat : CGFloat] = [:]
    private var cardFullHeightCache: [CGFloat : CGFloat] = [:]
    private var cardHeightWithInsetCache: [CGFloat : CGFloat] = [:]
    private var underCardControlYCache: [CGFloat : CGFloat] = [:]
    private var collectionScrollableContentYOffsetCache: [CGFloat : CGFloat] = [:]
    private var spaceToRecentActivitiesCache: [CGFloat : CGFloat] = [:]
    
    private init() { }
       
}

// MARK: - Open methods
extension DomainsCollectionUICache {
    func setCollectionViewHeight(_ collectionViewHeight: CGFloat) {
        if Int(collectionViewHeight) != Int(self.collectionViewHeight) {
            self.collectionViewHeight = collectionViewHeight
        }
    }
    
    func set(collectionViewYInContainer: CGFloat) {
        if Int(collectionViewYInContainer) != Int(self.collectionViewYInContainer) {
            self.collectionViewYInContainer = collectionViewYInContainer
        }
    }
   
    func cardFractionalHeight() -> CGFloat {
        cardFractionalHeight(for: collectionViewHeight)
    }
    
    func cardFullHeight() -> CGFloat {
        if let cachedValue = cardFullHeightCache[collectionViewHeight] {
            return cachedValue
        }
        let fullHeight = cardFractionalHeight() * collectionViewHeight
        cardFullHeightCache[collectionViewHeight] = fullHeight
        return fullHeight
    }
    
    func cardHeightWithTopInset() -> CGFloat {
        if let cachedValue = cardHeightWithInsetCache[collectionViewHeight] {
            return cachedValue
        }
        let heightWithInset = cardFullHeight() + DomainsCollectionCarouselItemViewController.scrollViewTopInset
        cardHeightWithInsetCache[collectionViewHeight] = heightWithInset
        return heightWithInset
    }
    
    func underCardControlY() -> CGFloat {
        if let cachedValue = underCardControlYCache[collectionViewHeight] {
            return cachedValue
        }
        let cardMaxY = cardHeightWithTopInset()
        let distanceFromCardToControl: CGFloat = 28
        let domainCardY = cardMaxY + collectionViewYInContainer + distanceFromCardToControl
        underCardControlYCache[collectionViewHeight] = domainCardY
        return domainCardY
    }
    
    func collectionScrollableContentYOffset() -> CGFloat {
        if collectionViewHeight == 0 {
            return 1
        }
        if let cachedValue = collectionScrollableContentYOffsetCache[collectionViewHeight] {
            return cachedValue
        }
        let scrollableContentYOffset = cardHeightWithTopInset() - DomainsCollectionCarouselCardCell.minHeight - 10
        collectionScrollableContentYOffsetCache[collectionViewHeight] = scrollableContentYOffset
        return scrollableContentYOffset
    }
    
    func spaceToRecentActivitiesSection() -> CGFloat {
        if let cachedValue = spaceToRecentActivitiesCache[collectionViewHeight] {
            return cachedValue
        }
                
        let cellMaxY = cardHeightWithTopInset()
        
        let dashesSectionHeight: CGFloat = DomainsCollectionCarouselItemViewPresenter.dashesSeparatorSectionHeight + UICollectionView.SideOffset * 2
        let activitiesHeaderHeight = DomainsCollectionSectionHeader.height + UICollectionView.SideOffset
        let activityCellHeight = DomainsCollectionRecentActivityCell.height * 1.2
        let safeAreaTopInset = SceneDelegate.shared?.window?.safeAreaInsets.top ?? 0
        let bottomRequiredSpace: CGFloat = dashesSectionHeight + activitiesHeaderHeight + activityCellHeight + safeAreaTopInset
        
        let spaceToRecentActivities = collectionViewHeight - cellMaxY - bottomRequiredSpace
        
        spaceToRecentActivitiesCache[collectionViewHeight] = spaceToRecentActivities
        return spaceToRecentActivities
    }
}

// MARK: - Private methods
private extension DomainsCollectionUICache {
    func invalidateCache() {
        cardFractionalHeightCache.removeAll()
        cardFullHeightCache.removeAll()
        cardHeightWithInsetCache.removeAll()
        underCardControlYCache.removeAll()
        collectionScrollableContentYOffsetCache.removeAll()
        spaceToRecentActivitiesCache.removeAll()
    }
    
    func cardFractionalHeight(for collectionViewHeight: CGFloat) -> CGFloat {
        guard collectionViewHeight != 0 else { return 0 }
        if let cachedValue = cardFractionalHeightCache[collectionViewHeight] {
            return cachedValue
        }
        
        let requiredWidth = UIScreen.main.bounds.width * DomainsCollectionCarouselItemViewController.cardFractionalWidth
        let requiredHeight = requiredWidth * nominalCardAspectRatio
        let fractionalHeight = requiredHeight / collectionViewHeight
        cardFractionalHeightCache[collectionViewHeight] = fractionalHeight
        return fractionalHeight
    }
    
}
