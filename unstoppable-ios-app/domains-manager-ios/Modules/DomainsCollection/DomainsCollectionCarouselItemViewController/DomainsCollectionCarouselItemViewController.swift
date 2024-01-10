//
//  DomainsCollectionCarouselViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

@MainActor
protocol DomainsCollectionCarouselItemViewProtocol: BaseCollectionViewControllerProtocol {
    var containerViewController: BaseViewController? { get }
    func applySnapshot(_ snapshot: DomainsCollectionCarouselItemSnapshot, animated: Bool)
    func endRefreshing()
}

typealias DomainsCollectionCarouselItemDataSource = UICollectionViewDiffableDataSource<DomainsCollectionCarouselItemViewController.Section, DomainsCollectionCarouselItemViewController.Item>
typealias DomainsCollectionCarouselItemSnapshot = NSDiffableDataSourceSnapshot<DomainsCollectionCarouselItemViewController.Section, DomainsCollectionCarouselItemViewController.Item>
typealias DomainsCollectionVisibleDataType = DomainsCollectionCarouselItemViewController.VisibleDataType
typealias DomainsCollectionVisibleDataTypeCallback = (DomainsCollectionVisibleDataType)->()

final class DomainsCollectionCarouselItemViewController: BaseViewController {
    
    static let cardFractionalWidth: CGFloat = 0.877
    static let scrollViewTopInset: CGFloat = 30
    
    private(set) var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainsCollectionCarouselCardCell.self,
                                                        DomainsCollectionRecentActivityCell.self,
                                                        DomainsCollectionNoRecentActivitiesCell.self,
                                                        DomainsCollectionDataTypeSelectionCell.self,
                                                        DomainsCollectionNFTCell.self,
                                                        DomainsCollectionSuggestionCell.self,
                                                        DomainsCollectionGetDomainCardCell.self] }
    
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    private var dataSource: DomainsCollectionCarouselItemDataSource!
    private(set) weak var containerViewController: BaseViewController?
    weak var delegate: DomainsCollectionCarouselViewControllerDelegate?
    var presenter: DomainsCollectionCarouselItemViewPresenterProtocol!
    private var cardState: CarouselCardState = .expanded
    
    static func instantiate(mode: DomainsCollectionCarouselItemDisplayMode,
                            cardState: CarouselCardState,
                            containerViewController: BaseViewController,
                            actionsDelegate: DomainsCollectionCarouselViewControllerActionsDelegate) -> DomainsCollectionCarouselItemViewController {
        let vc = DomainsCollectionCarouselItemViewController()
        vc.containerViewController = containerViewController
        let presenter = DomainsCollectionCarouselItemViewPresenter(view: vc,
                                                                   mode: mode,
                                                                   cardState: cardState,
                                                                   actionsDelegate: actionsDelegate)
        vc.presenter = presenter
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        configureCollectionView()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
    }
}

// MARK: - DomainsCollectionCarouselViewController
extension DomainsCollectionCarouselItemViewController: DomainsCollectionCarouselViewController {
    var contentOffsetRelativeToInset: CGPoint { collectionView.offsetRelativeToInset }

    func updateScrollOffset(_ offset: CGPoint) {
        collectionView.contentOffset = offset
        adjustCellsFor(offset: offset)
    }
    
    private func adjustCellsFor(offset: CGPoint) {
        var relativeOffset = offset
        relativeOffset.y += collectionView.contentInset.top
        if collectionView.refreshControl?.isRefreshing  == true {
            relativeOffset.y -= 60
        }
        
        for cell in collectionView.visibleCells {
            if let scrollListener = cell as? ScrollViewOffsetListener {
                scrollListener.didScrollTo(offset: relativeOffset)
            }
        }
    }
    
    func updateVisibilityLevel(_ visibilityLevel: CarouselCellVisibilityLevel) {
        guard let cell = self.collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? DomainsCollectionCarouselCardCell else { return }
        
        cell.updateVisibility(level: visibilityLevel)
    }
    
    func updateDecelerationRate(_ decelerationRate: UIScrollView.DecelerationRate) {
        collectionView.decelerationRate = decelerationRate
    }
    
    func setCarouselCardState(_ state: CarouselCardState) {
        self.cardState = state
        presenter.setCarouselCardState(state)
    }
    
    func endRefreshing() {
        refreshControl?.endRefreshing()
    }
}

// MARK: - DomainsCollectionCarouselItemViewProtocol
extension DomainsCollectionCarouselItemViewController: DomainsCollectionCarouselItemViewProtocol {
    func applySnapshot(_ snapshot: DomainsCollectionCarouselItemSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension DomainsCollectionCarouselItemViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        if offset.y > Self.scrollViewTopInset,
           let refreshControl,
           refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        adjustCellsFor(offset: offset)
        delegate?.carouselViewController(self, didScrollIn: scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didFinishScrolling()
        }
        if let refreshControl,
           refreshControl.isRefreshing,
        refreshControl.bounds.height < 60 {
            refreshControl.endRefreshing()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if var targetPoint = delegate?.carouselViewController(self,
                                                              willEndDraggingAtTargetContentOffset: targetContentOffset.pointee,
                                                              velocity: velocity,
                                                              currentContentOffset: collectionView.contentOffset) {
            if let refreshControl,
               refreshControl.isRefreshing  == true {
                targetPoint.y += refreshControl.bounds.height
            }
            targetContentOffset.pointee = targetPoint
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didFinishScrolling()
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewController {
    var refreshControl: UIRefreshControl? {
        collectionView.refreshControl
    }
    
    func didFinishScrolling() {
        delegate?.carouselViewController(self, didFinishScrollingAt: collectionView.contentOffset)
    }
    
    @objc func handleRefresh() {
        presenter.didPullToRefresh()
    }
}

// MARK: - Setup methods
private extension DomainsCollectionCarouselItemViewController {
    func setup() {
        view.backgroundColor = .clear
        setupCollectionView()
        // Align cards
        DispatchQueue.main.async {
            self.collectionView.setContentOffset(CGPoint(x: 1,
                                                         y: -self.collectionView.contentInset.top - 1),
                                                 animated: false)
        }
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: buildLayout())
        collectionView.embedInSuperView(view)
        collectionView.delegate = self
        collectionView.register(DomainsCollectionSectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DomainsCollectionSectionHeader.reuseIdentifier)
        collectionView.register(CollectionDashesHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier)
        collectionView.register(DomainsCollectionDashesSwipeTutorialHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: DomainsCollectionDashesSwipeTutorialHeader.reuseIdentifier)
        collectionView.register(EmptyCollectionSectionFooter.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: EmptyCollectionSectionFooter.reuseIdentifier)
        collectionView.register(EmptyCollectionSectionFooter.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: EmptyCollectionSectionFooter.reuseIdentifier)
        
        collectionView.contentInset.top = Self.scrollViewTopInset
        collectionView.clipsToBounds = false
        collectionView.decelerationRate = .init(rawValue: 0.99)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        refreshControl.backgroundColor = .backgroundDefault.withAlphaComponent(0.01)
        collectionView.refreshControl = refreshControl
        
        configureDataSource()
    }
   
    func configureDataSource() {
        dataSource = DomainsCollectionCarouselItemDataSource.init(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
            switch item {
            case .domainCard(let configuration):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionCarouselCardCell.self, forIndexPath: indexPath)
                
                cell.didScrollTo(offset: collectionView.offsetRelativeToInset)
                cell.setWith(configuration: configuration)
                
                DispatchQueue.main.async {
                    self?.delegate?.updatePagesVisibility()
                }
                
                return cell
            case .recentActivity(let configuration):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionRecentActivityCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .noRecentActivities(let configuration):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionNoRecentActivitiesCell.self, forIndexPath: indexPath)
                
                let cellHeight = DomainsCollectionUICache.shared.cardHeightWithTopInset()
                cell.setCellHeight(cellHeight,
                                   isTutorialOn: configuration.isTutorialOn,
                                   dataType: configuration.dataType)
                cell.didScrollTo(offset: collectionView.offsetRelativeToInset)
                cell.learnMoreButtonPressedCallback = configuration.learnMoreButtonPressedCallback
             
                return cell
            case .dataTypeSelector(let configuration):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionDataTypeSelectionCell.self, forIndexPath: indexPath)
                
                cell.setupWith(selectedDataType: configuration.selectedDataType,
                               dataTypeChangedCallback: configuration.dataTypeChangedCallback)
                
                return cell
            case .nft(let configuration):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionNFTCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .suggestion(let configuration):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionSuggestionCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .getDomainCard:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionGetDomainCardCell.self, forIndexPath: indexPath)
                cell.didScrollTo(offset: collectionView.offsetRelativeToInset)
                
                DispatchQueue.main.async {
                    self?.delegate?.updatePagesVisibility()
                }
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            
            @MainActor
            func createEmptySectionView() -> UICollectionReusableView {
                collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                withReuseIdentifier: EmptyCollectionSectionFooter.reuseIdentifier,
                                                                for: indexPath) as! EmptyCollectionSectionFooter
            }
            
            
            if elementKind == UICollectionView.elementKindSectionHeader {
                let section = self?.section(at: indexPath) ?? .noRecentActivities
                
                switch section {
                case .recentActivity:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: DomainsCollectionSectionHeader.reuseIdentifier,
                                                                               for: indexPath) as! DomainsCollectionSectionHeader
                    
                    view.setHeader(section.title)
                    return view
                case .tutorialDashesSeparator:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: DomainsCollectionDashesSwipeTutorialHeader.reuseIdentifier,
                                                                               for: indexPath) as! DomainsCollectionDashesSwipeTutorialHeader
                    
                    return view
                case .emptySeparator:
                    return createEmptySectionView()
                default:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier,
                                                                               for: indexPath) as! CollectionDashesHeaderReusableView
                    
                    view.setDashesConfiguration(.domainsCollection)
                    view.setAlignmentPosition(.center)
                    return view
                }
            } else {
                return createEmptySectionView()
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
        let orthogonalSectionInset: CGFloat = 0
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            guard let self,
                  let sectionKind = self.section(at: IndexPath(item: 0, section: sectionIndex)) else { fatalError("unknown section kind") }
            
            var section: NSCollectionLayoutSection = .flexibleListItemSection()
            let sectionHeaderHeight = sectionKind.headerHeight
            
            @MainActor
            func setSectionContentInset() {
                section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                leading: spacing + 1,
                                                                bottom: 1,
                                                                trailing: spacing + 1)
            }
            
            @MainActor
            func addHeader(offset: CGPoint = .zero) {
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                        heightDimension: .absolute(sectionHeaderHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top,
                                                                         absoluteOffset: offset)
                section.boundarySupplementaryItems.append(header)
            }
            
            @MainActor
            func addFooter(size: CGFloat) {
                let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                        heightDimension: .absolute(size))
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize,
                                                                         elementKind: UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottom)
                section.boundarySupplementaryItems.append(footer)
            }
            
            switch sectionKind {
            case .domainsCarousel:
                let leadingItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                            heightDimension: .fractionalHeight(1.0)))
                leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: orthogonalSectionInset,
                                                                    bottom: 0, trailing: orthogonalSectionInset)
                
                let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                                           heightDimension: .absolute(DomainsCollectionUICache.shared.cardFullHeight())),
                                                                        subitems: [leadingItem])
                section = NSCollectionLayoutSection(group: containerGroup)
                let bottomInset: CGFloat = self.cardState == .expanded ? 8 : 0
                section.contentInsets = .init(top: 0, leading: 24,
                                              bottom: bottomInset, trailing: 24)
            case .recentActivity(let numberOfActivities):
                let rowHeight: CGFloat = DomainsCollectionRecentActivityCell.height
                setSectionContentInset()
                addHeader(offset: .init(x: 0, y: -14))
                let sectionHeight = rowHeight * CGFloat(numberOfActivities)
                let sectionMinimumHeight = self.collectionView.bounds.height
                if sectionHeight < sectionMinimumHeight {
                    addFooter(size: sectionMinimumHeight - sectionHeight)
                }
            case .dashesSeparator, .tutorialDashesSeparator:
                addHeader()
                setSectionContentInset()
                section.contentInsets.top = -14
            case .emptySeparator(_, let height, let placement):
                switch placement {
                case .header:
                    addHeader()
                case .footer:
                    addFooter(size: height)
                }
            case .noRecentActivities:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .estimated(60)))
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .fractionalHeight(0.95)),
                    subitems: [item])
                
                section = NSCollectionLayoutSection(group: containerGroup)
                section.interGroupSpacing = 12
                section.contentInsets = .init(top: 0, leading: 12,
                                              bottom: 0, trailing: 12)
            case .dataTypeSelector:
                section = .flexibleListItemSection()
                section.contentInsets = .init(top: 0, leading: 16,
                                              bottom: 0, trailing: 16)
            case .nfts:
//                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
//                                                      heightDimension: .fractionalHeight(1.0))
//                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let inset: CGFloat = 8
//                item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
//
//                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
//                                                       heightDimension: .fractionalWidth(0.5))
//                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
//                                                               subitems: [item])
                
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)

                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalWidth(0.5))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
                let spacing = CGFloat(inset)
                
                
                section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: inset,
                                              bottom: 100, trailing: inset)
            }
            
            return section
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

extension DomainsCollectionCarouselItemViewController {
    enum Section: Hashable, Sendable {
        case domainsCarousel
        case recentActivity(numberOfActivities: Int)
        case noRecentActivities
        case dashesSeparator(id: UUID = .init(), height: CGFloat)
        case tutorialDashesSeparator(id: UUID = .init(), height: CGFloat)
        case emptySeparator(id: UUID = .init(), height: CGFloat, placement: EmptySeparatorPlacement)
        case dataTypeSelector
        case nfts

        var title: String {
            switch self {
            case .recentActivity:
                return String.Constants.connectedAppsTitle.localized()
            case .domainsCarousel, .noRecentActivities, .dashesSeparator, .tutorialDashesSeparator, .emptySeparator, .dataTypeSelector, .nfts:
                return ""
            }
        }
        
        var headerHeight: CGFloat {
            switch self {
            case .recentActivity:
                return DomainsCollectionSectionHeader.height
            case .dashesSeparator(_, let height), .tutorialDashesSeparator(_, let height), .emptySeparator(_, let height, _):
                return height
            case .domainsCarousel, .noRecentActivities, .dataTypeSelector, .nfts:
                return 0
            }
        }
        
        enum EmptySeparatorPlacement {
            case header, footer
        }
    }
    
    enum Item: Hashable, Sendable {
        case domainCard(configuration: DomainCardConfiguration)
        case recentActivity(configuration: RecentActivitiesConfiguration)
        case noRecentActivities(configuration: NoRecentActivitiesConfiguration)
        case dataTypeSelector(configuration: DataTypeSelectionConfiguration)
        case nft(configuration: NFTConfiguration)
        case suggestion(configuration: SuggestionConfiguration)
        case getDomainCard
    }
    
    struct DomainCardConfiguration: Hashable, Sendable {
        let id: UUID
        let domain: DomainDisplayInfo
        let availableActions: [Self.Action]
        let actionButtonPressedCallback: MainActorAsyncCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.domain == rhs.domain &&
            lhs.availableActions == rhs.availableActions
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(domain)
            hasher.combine(availableActions)
        }
        
        enum Action: Hashable {
            case openDomainProfile(callback: MainActorAsyncCallback)
            case copyDomain(callback: MainActorAsyncCallback)
            case viewVault(vaultName: String, vaultAddress: String, callback: MainActorAsyncCallback)
            case setUpRR(isEnabled: Bool, callback: MainActorAsyncCallback)
            case rearrange(callback: MainActorAsyncCallback)
            
            var title: String {
                switch self {
                case .openDomainProfile:
                    return String.Constants.viewProfile.localized()
                case .copyDomain:
                    return String.Constants.copyDomain.localized()
                case .viewVault(let vaultName, _, _):
                    return String.Constants.viewWallet.localized(vaultName.lowercased())
                case .setUpRR:
                    return String.Constants.setupReverseResolution.localized()
                case .rearrange:
                    return String.Constants.rearrange.localized()
                }
            }
            
            var subtitle: String? {
                switch self {
                case .openDomainProfile, .copyDomain, .setUpRR, .rearrange:
                    return nil
                case .viewVault(_, let vaultAddress, _):
                    return vaultAddress.walletAddressTruncated
                }
            }
            
            var icon: UIImage {
                switch self {
                case .openDomainProfile:
                    return .personCropCircle!
                case .copyDomain:
                    return .systemDocOnDoc
                case .viewVault:
                    return .arrowUpRight
                case .setUpRR:
                    return .arrowRightArrowLeft
                case .rearrange:
                    return .systemChevronUpDown
                }
            }
            
            static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.openDomainProfile, .openDomainProfile):
                    return true
                case (.copyDomain, .copyDomain):
                    return true
                case (.viewVault, .viewVault):
                    return true
                case (.setUpRR(let lhsEnabled, _), .setUpRR(let rhsEnabled, _)):
                    return lhsEnabled == rhsEnabled
                case (.rearrange, .rearrange):
                    return true
                default:
                    return false
                }
            }
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .copyDomain:
                    hasher.combine(0)
                case .viewVault:
                    hasher.combine(1)
                case .setUpRR(let isEnabled, _):
                    hasher.combine(isEnabled)
                    hasher.combine(2)
                case .rearrange:
                    hasher.combine(3)
                case .openDomainProfile:
                    hasher.combine(4)
                }
            }
        }
    }
    
    struct RecentActivitiesConfiguration: Hashable, Sendable {
        private let appHolder: UnifiedConnectedAppInfoHolder
        let availableActions: [Self.Action]
        let actionButtonPressedCallback: MainActorAsyncCallback
        
        var connectedApp: any UnifiedConnectAppInfoProtocol { appHolder.app }

        init(connectedApp: any UnifiedConnectAppInfoProtocol, availableActions: [DomainsCollectionCarouselItemViewController.RecentActivitiesConfiguration.Action], actionButtonPressedCallback: @escaping MainActorAsyncCallback) {
            self.appHolder = .init(app: connectedApp)
            self.availableActions = availableActions
            self.actionButtonPressedCallback = actionButtonPressedCallback
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.appHolder == rhs.appHolder &&
            lhs.availableActions == rhs.availableActions
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(appHolder)
            hasher.combine(availableActions)
        }
        
        enum Action: Hashable {
            case openApp(callback: MainActorAsyncCallback)
            case disconnect(callback: MainActorAsyncCallback)
            var title: String {
                switch self {
                case .openApp:
                    return String.Constants.recentActivityOpenApp.localized()
                case .disconnect:
                    return String.Constants.disconnect.localized()
                }
            }
            
            var subtitle: String? {
                switch self {
                case .openApp, .disconnect:
                    return nil
                }
            }
            
            var icon: UIImage {
                switch self {
                case .openApp:
                    return .safari
                case .disconnect:
                    return .systemMultiplyCircle
                }
            }
            
            static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.openApp, .openApp):
                    return true
                case (.disconnect, .disconnect):
                    return true
                default:
                    return false
                }
            }
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .disconnect:
                    hasher.combine(0)
                case .openApp:
                    hasher.combine(1)
                }
            }
        }
    }
    
    struct NoRecentActivitiesConfiguration: Hashable {
        let id = UUID()
        var learnMoreButtonPressedCallback: MainActorAsyncCallback
        var isTutorialOn: Bool
        var dataType: DomainsCollectionVisibleDataType

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.isTutorialOn == rhs.isTutorialOn &&
            lhs.dataType == rhs.dataType
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(isTutorialOn)
            hasher.combine(dataType)
        }
    }
    
    enum Action {
        case recentActivityLearnMore
        case recentActivityGetDomain
        case domainSelected(_ domain: DomainDisplayInfo)
        case nftSelected(_ nft: NFTModel)
        case domainNameCopied
        case rearrangeDomains
        case parkedDomainLearnMore
        case purchaseDomains
        case suggestionSelected(HotFeatureSuggestion)
    }
    
    struct DataTypeSelectionConfiguration: Hashable {
        let selectedDataType: DomainsCollectionVisibleDataType
        let dataTypeChangedCallback: DomainsCollectionVisibleDataTypeCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.selectedDataType == rhs.selectedDataType
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(selectedDataType)
        }
    }
    
    enum VisibleDataType: Int, CaseIterable, Hashable {
        case NFT, activity, parkedDomain, getDomain
        
        var title: String {
            switch self {
            case .NFT:
                return "NFTs"
            case .activity, .parkedDomain:
                return String.Constants.activity.localized()
            case .getDomain:
                return ""
            }
        }
        
        var icon: UIImage {
            switch self {
            case .NFT:
                return .hexagonIcon24
            case .activity, .parkedDomain, .getDomain:
                return .timeIcon24
            }
        }
        
        var analyticIdentifier: String {
            switch self {
            case .NFT:
                return "NFTs"
            case .activity, .parkedDomain:
                return "Activity"
            case .getDomain:
                return "getDomain"
            }
        }
    }
    
    struct NFTConfiguration: Hashable {
        let nft: NFTModel
    }
    
    struct SuggestionConfiguration: Hashable {
        let id = UUID()
        var closeCallback: MainActorAsyncCallback
        var suggestion: HotFeatureSuggestion
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id &&
            lhs.suggestion == rhs.suggestion
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(suggestion)
        }
    }
}

