//
//  ReviewAndConfirmTransferViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2023.
//

import UIKit

@MainActor
protocol ReviewAndConfirmTransferViewProtocol: BaseCollectionViewControllerProtocol & ViewWithDashesProgress {
    func applySnapshot(_ snapshot: ReviewAndConfirmTransferSnapshot, animated: Bool)
}

typealias ReviewAndConfirmTransferDataSource = UICollectionViewDiffableDataSource<ReviewAndConfirmTransferViewController.Section, ReviewAndConfirmTransferViewController.Item>
typealias ReviewAndConfirmTransferSnapshot = NSDiffableDataSourceSnapshot<ReviewAndConfirmTransferViewController.Section, ReviewAndConfirmTransferViewController.Item>

@MainActor
final class ReviewAndConfirmTransferViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [CollectionViewHeaderCell.self,
                                                        ReviewTransferDetailsCell.self] }
    var presenter: ReviewAndConfirmTransferViewPresenterProtocol!
    private var dataSource: ReviewAndConfirmTransferDataSource!
    override var scrollableContentYOffset: CGFloat? { 23 }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - ReviewAndConfirmTransferViewProtocol
extension ReviewAndConfirmTransferViewController: ReviewAndConfirmTransferViewProtocol {
    var progress: Double? { presenter.progress }

    func applySnapshot(_ snapshot: ReviewAndConfirmTransferSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension ReviewAndConfirmTransferViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            cNavigationController?.underlyingScrollViewDidFinishScroll(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidFinishScroll(scrollView)
    }
}

// MARK: - Private functions
private extension ReviewAndConfirmTransferViewController {

}

// MARK: - Setup functions
private extension ReviewAndConfirmTransferViewController {
    func setup() {
        addProgressDashesView()
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 50

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ReviewAndConfirmTransferDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .header:
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                cell.setTitle(String.Constants.reviewAndConfirm.localized(),
                              subtitleDescription: nil,
                              icon: nil)
                
                return cell
            case .transferDetails(let configuration):
                let cell = collectionView.dequeueCellOfType(ReviewTransferDetailsCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            }
        })
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            let layoutSection: NSCollectionLayoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            func addBackground() {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                layoutSection.decorationItems = [background]
            }
            
            switch section {
            case .header, .transferDetails, .none:
                Void()
            default:
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                layoutSection.decorationItems = [background]
            }
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
}

// MARK: - Collection elements
extension ReviewAndConfirmTransferViewController {
    enum Section: Int, Hashable {
        case header, transferDetails, consentItems, clearRecords
    }
    
    enum Item: Hashable {
        case header
        case transferDetails(configuration: TransferDetailsConfiguration)
    }
    
    struct TransferDetailsConfiguration: Hashable {
        let domain: DomainDisplayInfo
        let recipient: TransferDomainNavigationManager.RecipientType
    }
}
