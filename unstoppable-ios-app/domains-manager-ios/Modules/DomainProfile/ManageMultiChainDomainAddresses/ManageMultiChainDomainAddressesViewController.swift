//
//  ManageMultiChainDomainAddressesViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.05.2022.
//

import UIKit

@MainActor
protocol ManageMultiChainDomainAddressesViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ManageMultiChainDomainAddressesSnapshot, animated: Bool)
    func scroll(to item: ManageMultiChainDomainAddressesViewController.Item)
    func setConfirmButtonEnabled(_ isHidden: Bool)
}

typealias ManageMultiChainDomainAddressesDataSource = UICollectionViewDiffableDataSource<ManageMultiChainDomainAddressesViewController.Section, ManageMultiChainDomainAddressesViewController.Item>
typealias ManageMultiChainDomainAddressesSnapshot = NSDiffableDataSourceSnapshot<ManageMultiChainDomainAddressesViewController.Section, ManageMultiChainDomainAddressesViewController.Item>

@MainActor
final class ManageMultiChainDomainAddressesViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var confirmButton: MainButton!
    
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var isObservingKeyboard: Bool { true }
    private var dataSource: ManageMultiChainDomainAddressesDataSource!
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }
    override var analyticsName: Analytics.ViewName { .manageMultiChainRecords }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.record : presenter.record]}
    var cellIdentifiers: [UICollectionViewCell.Type] { [ManageDomainTopInfoCell.self, ManageMultiChainDomainAddressCell.self] }
    var presenter: ManageMultiChainDomainAddressesViewPresenterProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        collectionView.contentInset.bottom = keyboardHeight + defaultBottomOffset
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        collectionView.contentInset.bottom = defaultBottomOffset
    }
    
    override func shouldPopOnBackButton() -> Bool {
        presenter.shouldPopOnBackButton()
    }
}

// MARK: - ManageMultiChainDomainAddressesViewProtocol
extension ManageMultiChainDomainAddressesViewController: ManageMultiChainDomainAddressesViewProtocol {
    func applySnapshot(_ snapshot: ManageMultiChainDomainAddressesSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func scroll(to item: ManageMultiChainDomainAddressesViewController.Item) {
        guard let ip = dataSource.indexPath(for: item) else { return }
        
        scrollToItemAt(indexPath: ip, atPosition: .top, animated: true)
    }
    
    func setConfirmButtonEnabled(_ isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
    }
}

// MARK: - UDNavigationBackButtonHandler
extension ManageMultiChainDomainAddressesViewController: UDNavigationBackButtonHandler {
  
}

// MARK: - UICollectionViewDelegate
extension ManageMultiChainDomainAddressesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}

// MARK: - Private functions
private extension ManageMultiChainDomainAddressesViewController {
    @IBAction func confirmButtonPressed() {
        logButtonPressedAnalyticEvents(button: .confirm)
        presenter.confirmButtonPressed()
    }
}

// MARK: - Setup functions
private extension ManageMultiChainDomainAddressesViewController {
    func setup() {
        confirmButton.setTitle(String.Constants.confirm.localized(), image: nil)
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.keyboardDismissMode = .interactive
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ManageMultiChainDomainAddressesDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .topInfo(let coin):
                let cell = collectionView.dequeueCellOfType(ManageDomainTopInfoCell.self, forIndexPath: indexPath)
                
                cell.setWith(coin: coin)
                
                return cell
            case .record(let coin, let address, let error, let callback):
                let cell = collectionView.dequeueCellOfType(ManageMultiChainDomainAddressCell.self, forIndexPath: indexPath)
                
                cell.setWith(coin: coin,
                             address: address,
                             error: error,
                             actionCallback: callback)
                
                return cell
            }
        })
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection
            
            if sectionIndex == 0 { // Top info
                layoutSection = .listItemSection(height: 209)
            } else {
                layoutSection = .flexibleListItemSection()
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                      leading: spacing + 1,
                                                                      bottom: 1,
                                                                      trailing: spacing + 1)
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                layoutSection.decorationItems = [background]
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ManageMultiChainDomainAddressesViewController {
    enum Section: Int, Hashable {
        case topInfo, primaryChain, records
    }
    
    enum Item: Hashable, Sendable {
        case topInfo(_ coin: CoinRecord)
        case record(_ coin: CoinRecord,
                    address: String,
                    error: CryptoRecord.RecordError?,
                    actionCallback: MultichainDomainRecordActionCallback)
        
        static func == (lhs: ManageMultiChainDomainAddressesViewController.Item, rhs: ManageMultiChainDomainAddressesViewController.Item) -> Bool {
            switch (lhs, rhs) {
            case (.topInfo(let lhsCoin), .topInfo(let rhsCoin)):
                return lhsCoin == rhsCoin
            case (.record(let lhsCoin, let lhsAddress, let lhsError, _), .record(let rhsCoin, let rhsAddress, let rhsError,  _)):
                return lhsCoin == rhsCoin && lhsAddress == rhsAddress && lhsError == rhsError
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .topInfo(let coin):
                hasher.combine(coin)
            case .record(let coin, let address, let error, _):
                hasher.combine(coin)
                hasher.combine(address)
                hasher.combine(error)
            }
        }
    }
    
    enum RecordEditingAction {
        case beginEditing, addressChanged(_ address: String), clearButtonPressed, endEditing
    }
    
}
