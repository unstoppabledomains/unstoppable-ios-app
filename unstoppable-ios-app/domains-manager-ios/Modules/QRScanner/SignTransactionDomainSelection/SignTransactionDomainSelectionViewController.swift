//
//  SignTransactionDomainSelectionViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import UIKit

@MainActor
protocol SignTransactionDomainSelectionViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: SignTransactionDomainSelectionSnapshot, animated: Bool)
}

typealias SignTransactionDomainSelectionDataSource = UICollectionViewDiffableDataSource<SignTransactionDomainSelectionViewController.Section, SignTransactionDomainSelectionViewController.Item>
typealias SignTransactionDomainSelectionSnapshot = NSDiffableDataSourceSnapshot<SignTransactionDomainSelectionViewController.Section, SignTransactionDomainSelectionViewController.Item>

@MainActor
final class SignTransactionDomainSelectionViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainSelectionCell.self,
                                                        DomainsCollectionSearchEmptyCell.self,
                                                        CollectionViewShowHideCell.self] }
    var presenter: SignTransactionDomainSelectionViewPresenterProtocol!
    private var dataSource: SignTransactionDomainSelectionDataSource!
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }
  
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { .signWCTransactionDomainSelection }
    override var scrollableContentYOffset: CGFloat? { 32 }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? { cSearchBarConfiguration }
    private lazy var cSearchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration = {
        .init { [weak self] in 
            let searchBar = UDSearchBar()
            searchBar.delegate = self
            
            return searchBar
        }
    }()

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
}

// MARK: - SignTransactionDomainSelectionViewProtocol
extension SignTransactionDomainSelectionViewController: SignTransactionDomainSelectionViewProtocol {
    func applySnapshot(_ snapshot: SignTransactionDomainSelectionSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension SignTransactionDomainSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - UISearchBarDelegate
extension SignTransactionDomainSelectionViewController: UDSearchBarDelegate {
    func udSearchBarTextDidBeginEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStartSearching)
        presenter.didStartSearch()
    }
    
    func udSearchBar(_ udSearchBar: UDSearchBar, textDidChange searchText: String) {
        logAnalytic(event: .didSearch, parameters: [.domainName : searchText])
        presenter.didSearchWith(key: searchText)
    }
    
    func udSearchBarSearchButtonClicked(_ udSearchBar: UDSearchBar) {
        cNavigationBar?.setSearchActive(false, animated: true)
    }
    
    func udSearchBarCancelButtonClicked(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStopSearching)
        UDVibration.buttonTap.vibrate()
        setSearchBarActive(false)
        presenter.didStopSearch()
    }
    
    func udSearchBarTextDidEndEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStopSearching)
        setSearchBarActive(false)
        presenter.didStopSearch()
    }
}

// MARK: - Private functions
private extension SignTransactionDomainSelectionViewController {
    func setSearchBarActive(_ isActive: Bool) {
        cNavigationBar?.setSearchActive(isActive, animated: true)
    }
    
    func subheadButtonPressed() {
        logButtonPressedAnalyticEvents(button: .whatDoesReverseResolutionMean)
        presenter.subheadButtonPressed()
    }
}

// MARK: - Setup functions
private extension SignTransactionDomainSelectionViewController {
    func setup() {
        setupCollectionView()
        setupHeaderView()
    }
  
    func setupHeaderView() {
        let headerView = SignTransactionDomainSelectionHeaderView()
        headerView.subheadPressedCallback = { [weak self] in
            self?.subheadButtonPressed()
        }
        
        navigationItem.titleView = headerView
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 64
        collectionView.register(SignTransactionDomainSelectionSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: SignTransactionDomainSelectionSectionHeaderView.reuseIdentifier)
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = SignTransactionDomainSelectionDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .domain(let domain, let isSelected, let isReverseResolutionSet):
                let cell = collectionView.dequeueCellOfType(DomainSelectionCell.self, forIndexPath: indexPath)
                
                cell.setWith(domain: domain,
                             isSelected: isSelected,
                             indicator: isReverseResolutionSet ? .reverseResolution : nil)
                
                return cell
            case .emptyState:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionSearchEmptyCell.self, forIndexPath: indexPath)
                cell.setCenterYOffset(-40)
                
                return cell
            case .showOthers(let domainsCount, _):
                let cell = collectionView.dequeueCellOfType(CollectionViewShowHideCell.self, forIndexPath: indexPath)
                
                cell.setWith(text: String.Constants.showNMore.localized(domainsCount),
                             direction: .down,
                             height: 70)
                
                return cell
            case .hide:
                let cell = collectionView.dequeueCellOfType(CollectionViewShowHideCell.self, forIndexPath: indexPath)
                
                cell.setWith(text: String.Constants.hide.localized(),
                             direction: .up,
                             height: 70)
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let section = self?.section(at: indexPath) else { return nil }
            
            switch section {
            case .walletDomains(let walletName, _, let balance):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: SignTransactionDomainSelectionSectionHeaderView.reuseIdentifier,
                                                                           for: indexPath) as! SignTransactionDomainSelectionSectionHeaderView
                view.setHeader(for: walletName, balance: balance)
                return view
            case .selectedDomain, .emptyState:
                return nil
            }
        }
    }
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))
            let layoutSection: NSCollectionLayoutSection
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            switch section {
            case .walletDomains:
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(section?.headerHeight ?? 0))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            case .emptyState:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .zero
                
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .fractionalHeight(1)),
                    subitems: [item])
                let section = NSCollectionLayoutSection(group: containerGroup)
                section.contentInsets = .zero
                section.contentInsets.bottom = -368 // Keyboard height inset
                
                return section
            default:
                Void()
            }
            
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            background.contentInsets.top = section?.headerHeight ?? 0
            layoutSection.decorationItems = [background]
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension SignTransactionDomainSelectionViewController {
    enum Section: Hashable {
        case selectedDomain, walletDomains(walletName: String, walletAddress: String, balance: WalletBalance?), emptyState
        
        var headerHeight: CGFloat {
            switch self {
            case .walletDomains:
                return SignTransactionDomainSelectionSectionHeaderView.Height
            case .selectedDomain, .emptyState:
                return 0
            }
        }
    }
    
    enum Item: Hashable {
        case domain(_ domain: DomainDisplayInfo, isSelected: Bool, isReverseResolutionSet: Bool)
        case emptyState
        case showOthers(domainsCount: Int, walletAddress: HexAddress)
        case hide(walletAddress: HexAddress)
    }
}
