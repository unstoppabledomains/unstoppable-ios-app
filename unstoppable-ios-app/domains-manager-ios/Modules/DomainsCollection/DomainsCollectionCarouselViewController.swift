//
//  DomainsCollectionCarouselViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionCarouselViewControllerDelegate: AnyObject {
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, didScrollIn scrollView: UIScrollView)
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, didFinishScrollingAt offset: CGPoint)
    func carouselViewController(_ viewController: DomainsCollectionCarouselViewController, willEndDraggingAtTargetContentOffset targetContentOffset: CGPoint, velocity: CGPoint, currentContentOffset: CGPoint) -> CGPoint?
    func updatePagesVisibility()
}

@MainActor
protocol DomainsCollectionCarouselViewControllerActionsDelegate: AnyObject {
    func didOccurUIAction(_ action: DomainsCollectionCarouselItemViewController.Action)
}

@MainActor
protocol DomainsCollectionCarouselViewController: UIViewController {
    var collectionView: UICollectionView! { get }
    var page: Int { get set }
    var contentOffsetRelativeToInset: CGPoint { get }
    
    func updateScrollOffset(_ offset: CGPoint)
    func updateVisibilityLevel(_ visibilityLevel: CarouselCellVisibilityLevel)
    func updateDecelerationRate(_ decelerationRate: UIScrollView.DecelerationRate)
    func setCarouselCardState(_ state: CarouselCardState)
}

extension DomainsCollectionCarouselViewController {
    @MainActor
    var page: Int {
        get { view.tag }
        set { view.tag = newValue }
    }
}
