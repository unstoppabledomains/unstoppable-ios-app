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
    func setTransferButtonEnabled(_ isEnabled: Bool)
    func setLoadingIndicator(active: Bool)
}

typealias ReviewAndConfirmTransferDataSource = UICollectionViewDiffableDataSource<ReviewAndConfirmTransferViewController.Section, ReviewAndConfirmTransferViewController.Item>
typealias ReviewAndConfirmTransferSnapshot = NSDiffableDataSourceSnapshot<ReviewAndConfirmTransferViewController.Section, ReviewAndConfirmTransferViewController.Item>

@MainActor
final class ReviewAndConfirmTransferViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var transferButton: MainButton!

    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [CollectionViewHeaderCell.self,
                                                        ReviewTransferDetailsCell.self,
                                                        ReviewTransferSwitcherCell.self,
                                                        DomainTransactionInProgressCell.self] }
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
    
    func setTransferButtonEnabled(_ isEnabled: Bool) {
        transferButton.isEnabled = isEnabled
    }
    
    func setLoadingIndicator(active: Bool) {
        transferButton.isUserInteractionEnabled = !active
        if active {
            transferButton.showLoadingIndicator()
        } else {
            transferButton.hideLoadingIndicator()
        }
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

// MARK: - Actions
private extension ReviewAndConfirmTransferViewController {
    @IBAction func transferButtonPressed() {
        logButtonPressedAnalyticEvents(button: .transfer)
        presenter.transferButtonPressed()
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
        transferButton.setTitle(String.Constants.transfer.localized(), image: nil)
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
            case .switcher(let configuration):
                let cell = collectionView.dequeueCellOfType(ReviewTransferSwitcherCell.self, forIndexPath: indexPath)
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
            case .consentItems:
                layoutSection.interGroupSpacing = -11
                addBackground()
            default:
                addBackground()
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
        case switcher(configuration: TransferSwitcherConfiguration)
    }
    
    struct TransferDetailsConfiguration: Hashable {
        let domain: DomainDisplayInfo
        let recipient: TransferDomainNavigationManager.RecipientType
    }
    
    struct TransferSwitcherConfiguration: Hashable {
    
        let isOn: Bool
        let type: TransferSwitcherCellType
        var valueChangedCallback: ((Bool)->())
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.isOn == rhs.isOn &&
            lhs.type == rhs.type
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(isOn)
            hasher.combine(type)
        }
    }
    
    enum TransferSwitcherCellType: Hashable {
        case consentIrreversible
        case consentNotExchange
        case consentValidAddress
        case clearRecords
        
        var title: String {
            switch self {
            case .consentIrreversible:
                return String.Constants.transferConsentActionIrreversible.localized()
            case .consentNotExchange:
                return String.Constants.transferConsentNotExchange.localized()
            case .consentValidAddress:
                return String.Constants.transferConsentValidAddress.localized()
            case .clearRecords:
                return String.Constants.clearRecordsUponTransfer.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .consentIrreversible, .consentNotExchange, .consentValidAddress:
                return nil
            case .clearRecords:
                return String.Constants.optional.localized()
            }
        }
    }
}
