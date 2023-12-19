//
//  BaseCollectionViewControllerProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

@MainActor
protocol BaseCollectionViewControllerProtocol: BaseViewControllerProtocol {
    var collectionView: UICollectionView! { get }
    var cellIdentifiers: [UICollectionViewCell.Type] { get }
    var isRefreshControlEnabled: Bool { get }
    var refreshControlColor: UIColor { get }
    func configureCollectionView() // MARK: - Should be called in viewDidload()
    func reloadCollectionView()
    func collectionViewRefreshAction()
    func reloadSections(_ sections: IndexSet)
    func reloadItemsAt(indexPaths: [IndexPath])
    func insertItemsAt(indexPaths: [IndexPath])
    func deleteItemsAt(indexPaths: [IndexPath], completion: ((Bool)->())?)
    func setContentOffset(_ contentOffset: CGPoint, animated: Bool)
    func scrollToItemAt(indexPath: IndexPath, atPosition position: UICollectionView.ScrollPosition, animated: Bool)
    func reloadVisibleItems()
    func setScrollEnabled(_ isEnabled: Bool)
}

extension BaseCollectionViewControllerProtocol {
    var isRefreshControlEnabled: Bool { false }
    
    var refreshControlColor: UIColor { .label }
    
    func collectionViewRefreshAction() { }
    
    func reloadCollectionView() {
        collectionView?.reloadData()
    }
    
    func reloadSections(_ sections: IndexSet) {
        collectionView.reloadSections(sections)
    }
    
    func reloadItemsAt(indexPaths: [IndexPath]) {
        collectionView.performBatchUpdates({
            collectionView.reloadItems(at: indexPaths)
        }, completion: nil)
    }
    
    func insertItemsAt(indexPaths: [IndexPath]) {
        collectionView.performBatchUpdates({
            collectionView.insertItems(at: indexPaths)
        }, completion: nil)
    }
    
    func deleteItemsAt(indexPaths: [IndexPath], completion: ((Bool)->())? = nil) {
        collectionView?.performBatchUpdates({
            collectionView.deleteItems(at: indexPaths)
        }, completion: completion)
    }
    
    func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        collectionView.setContentOffset(contentOffset, animated: animated)
    }
    
    func scrollToItemAt(indexPath: IndexPath, atPosition position: UICollectionView.ScrollPosition, animated: Bool) {
        collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
    }
    
    func reloadVisibleItems() {
        reloadItemsAt(indexPaths: collectionView.indexPathsForVisibleItems)
    }
    
    func setScrollEnabled(_ isEnabled: Bool) {
        collectionView.isScrollEnabled = isEnabled
    }
    
    func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset.bottom = 32
        
        for cell in cellIdentifiers {
            guard Bundle.main.path(forResource: cell.cellIdentifier, ofType: "nib") != nil else { continue }
            collectionView.registerCellNibOfType(cell.self)
        }
    }
}

