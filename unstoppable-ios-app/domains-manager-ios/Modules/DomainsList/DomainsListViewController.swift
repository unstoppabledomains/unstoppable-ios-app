//
//  DomainsListViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

@MainActor
protocol DomainsListViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: DomainsListSnapshot, animated: Bool)
    func setLayout(_ layout: UICollectionViewLayout)
    func refreshTitle()
}

typealias DomainsListDataSource = UICollectionViewDiffableDataSource<DomainsListViewController.Section, DomainsListViewController.Item>
typealias DomainsListSnapshot = NSDiffableDataSourceSnapshot<DomainsListViewController.Section, DomainsListViewController.Item>

@MainActor
final class DomainsListViewController: BaseViewController, BlurVisibilityAfterLimitNavBarScrollingBehaviour {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var dataSource: DomainsListDataSource!
    private var defaultBottomOffset: CGFloat { Constants.scrollableContentBottomOffset }

    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainsCollectionSearchEmptyCell.self,
                                                        DomainsCollectionListCell.self,
                                                        DomainsCollectionMintingInProgressCell.self] }
    var presenter: DomainsListViewPresenterProtocol!
    override var isObservingKeyboard: Bool { true }
    override var scrollableContentYOffset: CGFloat? { presenter.scrollableContentYOffset }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var navBackStyle: BaseViewController.NavBackIconStyle { presenter.navBackStyle }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? { presenter.isSearchable ? cSearchBarConfiguration : nil }
    private var searchBar: UDSearchBar = UDSearchBar()
    private lazy var cSearchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration = {
        .init(searchBarPlacement: .inline) { [weak self] in
            let searchBar = self?.searchBar ?? UDSearchBar()
            searchBar.setCorrectionType(.no)
            searchBar.setAutoCapitalizationType(.none)
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
    
    override func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? {
        { [weak self, weak navBar] in
            guard let self,
                  let navBar else { return }
            
            self.updateBlurVisibility(for: yOffset, in: navBar)
        }
    }
    
    override func hideKeyboard() {
        super.hideKeyboard()
        
        cNavigationBar?.setSearchActive(false, animated: true)
    }
}

// MARK: - DomainsListViewProtocol
extension DomainsListViewController: DomainsListViewProtocol {
    func applySnapshot(_ snapshot: DomainsListSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func setLayout(_ layout: UICollectionViewLayout) {
        collectionView.collectionViewLayout = layout
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func refreshTitle() {
        title = presenter.title
        cNavigationController?.updateNavigationBar()
    }
}

// MARK: - UICollectionViewDelegate
extension DomainsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - UISearchBarDelegate
extension DomainsListViewController: UDSearchBarDelegate {
    func udSearchBarTextDidBeginEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStartSearching)
        setSearchBarActive(true)
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
    }
    
    func udSearchBarTextDidEndEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStopSearching)
        setSearchBarActive(false)
    }
}

// MARK: - Private functions
private extension DomainsListViewController {
    func setSearchBarActive(_ isActive: Bool) {
        let topInset: CGFloat = isActive ? 84 : 140
        collectionView.contentInset.top = topInset
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: -topInset),
                                                 animated: true)
        }
    }
    
    @objc func rearrangeButtonPressed() {
        logButtonPressedAnalyticEvents(button: .rearrangeDomains)
        presenter.rearrangeButtonPressed()
    }
}

// MARK: - Setup functions
private extension DomainsListViewController {
    func setup() {
        setupCollectionView()
        addRearrangeButtonIfNeeded()
        self.title = presenter.title
        searchBar.delegate = self
        searchBar.shouldAnimateStateUpdate = false
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = presenter.isSearchable ? 140 : 103
        collectionView.register(CollectionTextHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier)
        collectionView.register(CollectionDashesHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier)
        collectionView.register(DomainsGlobalSearchHintHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DomainsGlobalSearchHintHeader.reuseIdentifier)
        
        configureDataSource()
    }
    
    func addRearrangeButtonIfNeeded() {
        if presenter.isSearchable {
            let rearrangeButton = UDButton()
            rearrangeButton.setTitle(String.Constants.rearrange.localized(), image: nil)
            rearrangeButton.setConfiguration(.mediumGhostPrimaryButtonConfiguration(contentInset: .init(top: 0, left: 0, bottom: 0, right: 10)))
            rearrangeButton.addTarget(self, action: #selector(rearrangeButtonPressed), for: .touchUpInside)
            let rightBarButton = UIBarButtonItem(customView: rearrangeButton)
            
            navigationItem.rightBarButtonItems = [rightBarButton]
        }
    }
    
    func configureDataSource() {
        dataSource = DomainsListDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .domainListItem(let domainItem, let isSelectable):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionListCell.self, forIndexPath: indexPath)
                cell.setWith(domainItem: domainItem, isSelectable: isSelectable)
                
                return cell
            case .domainSearchItem(let searchDomain, let isSelectable):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionListCell.self, forIndexPath: indexPath)
                cell.setWith(searchDomain: searchDomain, isSelectable: isSelectable)
                
                return cell
            case .domainsMintingInProgress(let domainsCount):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionMintingInProgressCell.self, forIndexPath: indexPath)
                cell.setWith(domainsCount: domainsCount)
                
                return cell
            case .searchEmptyState:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionSearchEmptyCell.self, forIndexPath: indexPath)
                cell.setMode(.noResults)
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let section = self?.section(at: indexPath) else { return nil }
            
            switch section {
            case .other(let title):
                guard let title else { return nil }
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier,
                                                                           for: indexPath) as! CollectionTextHeaderReusableView
                view.setHeader(title)
                return view
            case .dashesSeparator:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier,
                                                                           for: indexPath) as! CollectionDashesHeaderReusableView
                view.setDashesConfiguration(.domainsCollection)
                
                return view
            case .globalSearchHint:
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: DomainsGlobalSearchHintHeader.reuseIdentifier,
                                                                           for: indexPath) as! DomainsGlobalSearchHintHeader
                
                return view
            default:
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
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))

            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            @MainActor
            func addBackground(inset: CGFloat? = nil) {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                if let inset {
                    background.contentInsets.top = inset
                }
                layoutSection.decorationItems = [background]
            }
            @MainActor
            func addHeader() {
                let headerHeight = section?.headerHeight ?? 0
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(headerHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            }
            
            switch section {
            case .other(let title):
                var inset: CGFloat?
                if title != nil {
                    addHeader()
                    inset = section?.headerHeight
                }
                
                addBackground(inset: inset)
            case .minting:
                addBackground()
            case .dashesSeparator:
                addHeader()
            case .globalSearchHint:
                addHeader()
            case .searchEmptyState, .none:
                Void()
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension DomainsListViewController {
    enum Section: Hashable, Sendable {
        case other(title: String?), minting, searchEmptyState, dashesSeparator, globalSearchHint
        
        var headerHeight: CGFloat {
            switch self {
            case .other: return CollectionTextHeaderReusableView.Height
            case .dashesSeparator: return 2
            case .globalSearchHint: return 40
            default: return 0
            }
        }
    }
    
    enum Item: Hashable, Sendable {
        case domainListItem(_ domainItem: DomainDisplayInfo, isSelectable: Bool)
        case domainSearchItem(_ domainItem: SearchDomainProfile, isSelectable: Bool)
        case domainsMintingInProgress(domainsCount: Int)
        case searchEmptyState
    }
}
