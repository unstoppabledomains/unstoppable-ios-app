//
//  ChoosePrimaryDomainViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

protocol ChoosePrimaryDomainViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var progress: Double? { get }
    var title: String { get }
    var isSearchable: Bool { get }
    func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item)
    
    func dragItem(_ item: ChoosePrimaryDomainViewController.Item, at indexPath: IndexPath) -> UIDragItem?
    func proposalForItemsWithDropSession(_ session: UIDropSession, destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal
    func didMoveItemsWith(transaction: ChoosePrimaryDomainMoveTransaction)
    func didStartSearch()
    func didStopSearch()
    func didSearchWith(key: String)

    func confirmButtonPressed()
    func reverseResolutionInfoHeaderPressed()
}

class ChoosePrimaryDomainViewPresenter {
    
    private(set) weak var view: ChoosePrimaryDomainViewProtocol?
    var progress: Double? { nil }
    var title: String { String.Constants.rearrangeDomainsTitle.localized() }
    var isSearchable: Bool { true }
    var analyticsName: Analytics.ViewName { .unspecified }
    private(set) var isSearchActive = false
    private(set) var searchKey: String = ""
    
    init(view: ChoosePrimaryDomainViewProtocol) {
        self.view = view
    }

    /// Update model in child class
    func didMoveItem(from fromIndex: Int, to toIndex: Int) { }
    
    // MARK: - ChoosePrimaryDomainViewPresenterProtocol
    func viewDidLoad() { }
    @MainActor func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item) { }
    func confirmButtonPressed() { }
    func reverseResolutionInfoHeaderPressed() {
        Task {
            guard let view = self.view else { return }
            
            await appContext.pullUpViewService.showWhatIsReverseResolutionInfoPullUp(in: view)
        }
    }
    @MainActor
    func didSearchWith(key: String) {
        self.searchKey = key.trimmedSpaces
    }
    @MainActor
    func didStartSearch() {
        self.isSearchActive = true
    }
    @MainActor
    func didStopSearch() {
        self.isSearchActive = false
        didSearchWith(key: "")
    }
}

// MARK: - ChoosePrimaryDomainViewPresenterProtocol
extension ChoosePrimaryDomainViewPresenter: ChoosePrimaryDomainViewPresenterProtocol {
    func dragItem(_ item: ChoosePrimaryDomainViewController.Item, at indexPath: IndexPath) -> UIDragItem? {
        guard item.isDraggable else { return nil }
        
        let object = IndexPathItemProvider(indexPath: indexPath)
        let provider = NSItemProvider(object: object)
        let dragItem = UIDragItem(itemProvider: provider)
        return dragItem
    }
    
    func proposalForItemsWithDropSession(_ session: UIDropSession, destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func didMoveItemsWith(transaction: ChoosePrimaryDomainMoveTransaction) {
        let difference = transaction.difference
        var fromOffset: Int?
        var toOffset: Int?
        
        for diff in difference {
            switch diff {
            case .remove(let offset, _, _):
                fromOffset = offset
            case .insert(let offset, _, _):
                toOffset = offset
            }
        }
        
        guard let fromOffset, let toOffset else { return }
        
        didMoveItem(from: fromOffset - 1, to: toOffset - 1)
    }
}

// MARK: - Private methods
private extension ChoosePrimaryDomainViewPresenter {
    final class IndexPathItemProvider: NSObject, NSItemProviderWriting, Codable {
        
        static var writableTypeIdentifiersForItemProvider: [String] { ["indexPath.unstoppable"] }
        
        let indexPath: IndexPath
        
        init(indexPath: IndexPath) {
            self.indexPath = indexPath
        }
        
        func loadData(withTypeIdentifier typeIdentifier: String,
                      forItemProviderCompletionHandler completionHandler: @escaping @Sendable (Data?, Error?) -> Void) -> Progress? {
            let progress = Progress(totalUnitCount: 100)
            do {
                //Here the object is encoded to a JSON data object and sent to the completion handler
                let data = try JSONEncoder().encode(self)
                progress.completedUnitCount = 100
                completionHandler(data, nil)
            } catch {
                completionHandler(nil, error)
            }
            return progress
        }
    }
}
