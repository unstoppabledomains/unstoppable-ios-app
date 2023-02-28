//
//  ChoosePrimaryDomainViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit

@MainActor
protocol ChoosePrimaryDomainViewProtocol: BaseCollectionViewControllerProtocol & ViewWithDashesProgress {
    func applySnapshot(_ snapshot: ChoosePrimaryDomainSnapshot, animated: Bool)
    func setConfirmButtonEnabled(_ isEnabled: Bool)
    func setConfirmButtonTitle(_ title: String)
    func setLoadingIndicator(active: Bool)
    func setTitleHidden(_ hidden: Bool)
    func stopSearching()
    func scrollTo(item: ChoosePrimaryDomainViewController.Item)
}

typealias ChoosePrimaryDomainDataSource = UICollectionViewDiffableDataSource<ChoosePrimaryDomainViewController.Section, ChoosePrimaryDomainViewController.Item>
typealias ChoosePrimaryDomainSnapshot = NSDiffableDataSourceSnapshot<ChoosePrimaryDomainViewController.Section, ChoosePrimaryDomainViewController.Item>
typealias ChoosePrimaryDomainMoveTransaction = NSDiffableDataSourceTransaction<ChoosePrimaryDomainViewController.Section, ChoosePrimaryDomainViewController.Item>

@MainActor
final class ChoosePrimaryDomainViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var gradientView: UDGradientCoverView!
    @IBOutlet private weak var confirmButton: MainButton!
    @IBOutlet private weak var moveToTopButton: FABButton!
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var buttonBackgroundView: UIView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [RearrangeDomainCell.self,
                                                        CollectionViewHeaderCell.self,
                                                        DomainsCollectionSearchEmptyCell.self] }
    var presenter: ChoosePrimaryDomainViewPresenterProtocol!
    private var dataSource: ChoosePrimaryDomainDataSource!
    private var isTitleHidden: Bool = false
    private var lastContentOffset: CGPoint = .zero
    override var isObservingKeyboard: Bool { true }
    override var navBackStyle: BaseViewController.NavBackIconStyle {
        if (self.cNavigationController is EmptyRootCNavigationController),
           cNavigationController?.viewControllers.first == self {
            return .cancel
        }
        return .arrow
    }
    override var prefersLargeTitles: Bool { !isTitleHidden }
    override var largeTitleAlignment: NSTextAlignment { .center }
    override var largeTitleIcon: UIImage? { isTitleHidden ? nil : .homeDomainInfoVisualisation }
    override var largeTitleIconSize: CGSize? { CGSize(width: 72, height: 124) }
    override var scrollableContentYOffset: CGFloat? { 10 }
    override var adjustLargeTitleFontSizeForSmallerDevice: Bool { true }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? { presenter.isSearchable ? cSearchBarConfiguration : nil }
    private var searchBar: UDSearchBar = UDSearchBar()
    private lazy var cSearchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration = {
        .init { [weak self] in
            self?.searchBar ?? UIView()
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.firstSubviewOfType(UILabel.self)?.isHidden = true
        presenter.viewWillAppear()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        collectionView.contentInset.bottom = keyboardHeight + Constants.scrollableContentBottomOffset - buttonBackgroundView.bounds.height
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        collectionView.contentInset.bottom = Constants.scrollableContentBottomOffset
    }
}

// MARK: - ChoosePrimaryDomainViewProtocol
extension ChoosePrimaryDomainViewController: ChoosePrimaryDomainViewProtocol {
    var progress: Double? { presenter.progress }
    
    func applySnapshot(_ snapshot: ChoosePrimaryDomainSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            self.collectionView.isScrollEnabled = (self.collectionView.contentSize.height + self.collectionView.contentInset.top + self.collectionView.contentInset.bottom) > self.collectionView.bounds.height
        }
    }
    
    func setConfirmButtonEnabled(_ isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
    }
    
    func setConfirmButtonTitle(_ title: String) {
        confirmButton.setTitle(title, image: nil)
    }
    
    func setLoadingIndicator(active: Bool) {
        confirmButton.isUserInteractionEnabled = !active
        if active {
            confirmButton.showLoadingIndicator()
        } else {
            confirmButton.hideLoadingIndicator()
        }
    }
    
    func setTitleHidden(_ hidden: Bool) {
        isTitleHidden = hidden
        collectionView.contentInset.top = hidden ? 50 : 286
        cNavigationController?.updateNavigationBar()
    }
    
    func stopSearching() {
        setSearchBarActive(false)
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func scrollTo(item: Item) {
        if let indexPath = dataSource.indexPath(for: item) {
            scrollToItemAt(indexPath: indexPath, atPosition: .centeredVertically, animated: true)
            Task {
                try? await Task.sleep(seconds: 0.3)
                if let cell = collectionView.cellForItem(at: indexPath) as? RearrangeDomainCell {
                    cell.blink(for: 2)
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ChoosePrimaryDomainViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setMoveToTopButton(hidden: scrollView.contentOffset.y < 100, animated: false)
        var contentOffset = scrollView.contentOffset
        if collectionView.hasActiveDrag,
           let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)),
           contentOffset.y < cell.frame.minY,
           contentOffset.y < lastContentOffset.y {
            contentOffset = lastContentOffset
            scrollView.setContentOffset(contentOffset, animated: false)
        }
        
        lastContentOffset = contentOffset
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        guard let item = dataSource.itemIdentifier(for: proposedIndexPath),
              item.isDraggable else { return currentIndexPath }
        
        return proposedIndexPath
    }
}

// MARK: - UICollectionViewDragDelegate
extension ChoosePrimaryDomainViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if let item = dataSource.itemIdentifier(for: indexPath),
           let dragItem = presenter.dragItem(item, at: indexPath) {
            return [dragItem]
        }
        return []
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] { [] }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool { true }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        
        let previewParameters = UIDragPreviewParameters()
        let path = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 8.0)
        previewParameters.visiblePath = path
        previewParameters.backgroundColor = .clear
        return previewParameters
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        cNavigationBar?.navBarContentView.setSearchBarButtonEnabled(false)
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        cNavigationBar?.navBarContentView.setSearchBarButtonEnabled(true)
    }
}

// MARK: - UICollectionViewDropDelegate
extension ChoosePrimaryDomainViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        return /// Handled via dataSource.reorderingHandlers.didReorder
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return presenter.proposalForItemsWithDropSession(session, destinationIndexPath: destinationIndexPath)
    }
}

// MARK: - UISearchBarDelegate
extension ChoosePrimaryDomainViewController: UDSearchBarDelegate {
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
        searchBar.text = ""
    }
    
    func udSearchBarCancelButtonClicked(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStopSearching)
        UDVibration.buttonTap.vibrate()
        presenter.didStopSearch()
        setSearchBarActive(false)
    }
    
    func udSearchBarTextDidEndEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStopSearching)
        setSearchBarActive(false)
        presenter.didStopSearch()
    }
}

// MARK: - Private functions
private extension ChoosePrimaryDomainViewController {
    @IBAction func confirmButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .confirm)
        presenter.confirmButtonPressed()
    }
    
    @IBAction func moveToTopButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .moveToTop)
        let ip = IndexPath(row: 0, section: 0)
        collectionView.scrollToItem(at: ip, at: .top, animated: true)
    }
    
    func setSearchBarActive(_ isActive: Bool) {
        cNavigationBar?.setSearchActive(isActive, animated: true)
    }
    
    func setMoveToTopButton(hidden: Bool, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.25 : 0.0) {
            self.moveToTopButton.alpha = hidden ? 0 : 1
        }
    }
}

// MARK: - Setup functions
private extension ChoosePrimaryDomainViewController {
    func setup() {
        addProgressDashesView()
        if presenter.progress == nil {
            setDashesProgress(nil)
        }
        searchBar.delegate = self
        setupCollectionView()
        self.title = presenter.title
        setupMoveToTopButton()
    }
 
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 286
        configureDataSource()
    }
    
    func setupMoveToTopButton() {
        moveToTopButton.customImageEdgePadding = 12
        moveToTopButton.customTitleEdgePadding = 12
        moveToTopButton.customFont = .medium
        moveToTopButton.setTitle(String.Constants.moveToTop.localized(), image: nil)
        setMoveToTopButton(hidden: true, animated: false)
    }
    
    func configureDataSource() {
        dataSource = ChoosePrimaryDomainDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            
            switch item {
            case .domainName(let domainName):
                let cell = collectionView.dequeueCellOfType(RearrangeDomainCell.self, forIndexPath: indexPath)
                cell.setWith(domainName: domainName)
                return cell
            case .domain(let domain, let reverseResolutionWalletInfo, let isSearching):
                let cell = collectionView.dequeueCellOfType(RearrangeDomainCell.self, forIndexPath: indexPath)
                cell.setWith(domain: domain,
                             reverseResolutionWalletInfo: reverseResolutionWalletInfo,
                             isSearching: isSearching)
                return cell
            case .header:
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                let subtitle = String.Constants.rearrangeDomainsSubtitle.localized()
                cell.setTitle(nil,
                              subtitleDescription: .init(subtitle: subtitle,
                                                         attributes: [.init(text: subtitle,
                                                                            alignment: .center)]),
                              icon: nil)
                return cell
            case .searchEmptyState(let mode):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionSearchEmptyCell.self, forIndexPath: indexPath)
                cell.setMode(mode)
                
                return cell
            }
        })
        
        dataSource.reorderingHandlers.canReorderItem = { item in return item.isDraggable }
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            self?.presenter.didMoveItemsWith(transaction: transaction)
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
            
            if let rowHeight = section?.rowHeight {
                layoutSection = .listItemSection(height: rowHeight)
            } else {
                layoutSection = .flexibleListItemSection()
            }
            
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            @MainActor
            func setBackground() {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                background.contentInsets.top = section?.headerHeight ?? 0
                layoutSection.decorationItems = [background]
            }
            
            switch section {
            case .allDomains:
                layoutSection.contentInsets.top = 16
                layoutSection.interGroupSpacing = 4
                setBackground()
            case .header, .none, .searchEmptyState:
                Void()
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ChoosePrimaryDomainViewController {
    enum Section: Int, Hashable {
        case header
        case allDomains
        case searchEmptyState
        
        var headerHeight: CGFloat {
            switch self {
            case .header, .searchEmptyState:
                return 0
            case .allDomains:
                return CollectionTextHeaderReusableView.Height
            }
        }
        
        var rowHeight: CGFloat? {
            switch self {
            case .header:
                return 32
            case .searchEmptyState:
                return 340
            case .allDomains:
                return 64
            }
        }
    }
    
    enum Item: Hashable {
        case domainName(_ domainName: String)
        case domain(_ domain: DomainDisplayInfo, reverseResolutionWalletInfo: WalletDisplayInfo?, isSearching: Bool)
        case header
        case searchEmptyState(mode: DomainsCollectionSearchEmptyCell.Mode)
        
        var isDraggable: Bool {
            switch self {
            case .searchEmptyState, .header:
                return false
            case .domainName:
                return true
            case .domain(_, _, let isSearching):
                return !isSearching
            }
        }
    }
}
