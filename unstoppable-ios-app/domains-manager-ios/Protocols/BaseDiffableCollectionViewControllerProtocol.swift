//
//  BaseDiffableCollectionViewControllerProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.07.2023.
//

import UIKit

@MainActor
protocol BaseDiffableCollectionViewControllerProtocol: BaseCollectionViewControllerProtocol {
    associatedtype Section: Hashable, Sendable
    associatedtype Item: Hashable, Sendable
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    var dataSource: DataSource! { get }
    var operationQueue: OperationQueue { get }
    
    func applySnapshot(_ snapshot: Snapshot, animated: Bool, completion: EmptyCallback?)
    func scrollToItem(_ item: Item, atPosition position: UICollectionView.ScrollPosition, animated: Bool)
}

// MARK: - Open methods
extension BaseDiffableCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: Snapshot, animated: Bool, completion: EmptyCallback?) {
        operationQueue.maxConcurrentOperationCount = 1
        let operation = CollectionReloadDiffableDataOperation(dataSource: dataSource,
                                                              snapshot: snapshot,
                                                              animated: animated,
                                                              completion: completion)
        operationQueue.addOperation(operation)
    }
    
    func scrollToItem(_ item: Item, atPosition position: UICollectionView.ScrollPosition, animated: Bool) {
        guard let indexPath = dataSource.indexPath(for: item) else { return }
        
        scrollToItemAt(indexPath: indexPath, atPosition: position, animated: animated)
    }
}

final class CollectionReloadDiffableDataOperation<Section, Item>: BaseOperation where Section: Hashable, Section: Sendable, Item: Hashable, Item: Sendable {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    let dataSource: DataSource
    let snapshot: Snapshot
    let animated: Bool
    let completion: EmptyCallback?
    
    init(dataSource: DataSource,
         snapshot: Snapshot,
         animated: Bool,
         completion: EmptyCallback? = nil) {
        self.dataSource = dataSource
        self.snapshot = snapshot
        self.animated = animated
        self.completion = completion
    }
    
    override func start() {
        guard !checkIfCancelled() else {
            completion?()
            return
        }
        dataSource.apply(snapshot, animatingDifferences: animated, completion: { [weak self] in
            DispatchQueue.main.async {
                self?.completion?()
                self?.finish(true)
            }
        })
    }
}
