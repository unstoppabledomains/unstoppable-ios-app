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
}

typealias DomainsCollectionCarouselItemDataSource = UICollectionViewDiffableDataSource<DomainsCollectionCarouselItemViewController.Section, DomainsCollectionCarouselItemViewController.Item>
typealias DomainsCollectionCarouselItemSnapshot = NSDiffableDataSourceSnapshot<DomainsCollectionCarouselItemViewController.Section, DomainsCollectionCarouselItemViewController.Item>

final class DomainsCollectionCarouselItemViewController: BaseViewController {
    
    static let cardFractionalWidth: CGFloat = 0.877
    static let scrollViewTopInset: CGFloat = 41
    
    private(set) var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [DomainsCollectionCarouselCardCell.self,
                                                        DomainsCollectionRecentActivityCell.self,
                                                        DomainsCollectionNoRecentActivitiesCell.self] }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    private var dataSource: DomainsCollectionCarouselItemDataSource!
    private(set) weak var containerViewController: BaseViewController?
    weak var delegate: DomainsCollectionCarouselViewControllerDelegate?
    var presenter: DomainsCollectionCarouselItemViewPresenterProtocol!
    
    static func instantiate(domain: DomainDisplayInfo,
                            containerViewController: BaseViewController,
                            actionsDelegate: DomainsCollectionCarouselViewControllerActionsDelegate) -> DomainsCollectionCarouselItemViewController {
        let vc = DomainsCollectionCarouselItemViewController()
        vc.containerViewController = containerViewController
        let presenter = DomainsCollectionCarouselItemViewPresenter(view: vc,
                                                                   domain: domain,
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
        presenter.setCarouselCardState(state)
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
        adjustCellsFor(offset: offset)
        delegate?.carouselViewController(self, didScrollIn: scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didFinishScrolling()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let targetPoint = delegate?.carouselViewController(self,
                                                              willEndDraggingAtTargetContentOffset: targetContentOffset.pointee,
                                                              velocity: velocity,
                                                              currentContentOffset: collectionView.contentOffset) {
            targetContentOffset.pointee = targetPoint
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didFinishScrolling()
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselItemViewController {
    func didFinishScrolling() {
        delegate?.carouselViewController(self, didFinishScrollingAt: collectionView.contentOffset)
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
        
        collectionView.contentInset.top = Self.scrollViewTopInset
        collectionView.clipsToBounds = false
        collectionView.decelerationRate = .init(rawValue: 0.99)
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
                
                let collectionViewHeight = collectionView.bounds.height
                let cellHeight = DomainsCollectionUICache.shared.cardHeightWithTopInset()
                let cellMinY = cellHeight + UICollectionView.SideOffset
                cell.setCellHeight(cellHeight,
                                   collectionHeight: collectionViewHeight,
                                   cellMinY: cellMinY)
                cell.didScrollTo(offset: collectionView.offsetRelativeToInset)
                cell.learnMoreButtonPressedCallback = configuration.learnMoreButtonPressedCallback
             
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
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
                default:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                               withReuseIdentifier: CollectionDashesHeaderReusableView.reuseIdentifier,
                                                                               for: indexPath) as! CollectionDashesHeaderReusableView
                    
                    view.setDashesConfiguration(.domainsCollection)
                    view.setAlignmentPosition(.center)
                    return view
                }
            } else {
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                                               withReuseIdentifier: EmptyCollectionSectionFooter.reuseIdentifier,
                                                                                               for: indexPath) as! EmptyCollectionSectionFooter
                
                return footerView
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
            
            func setSectionContentInset() {
                section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                leading: spacing + 1,
                                                                bottom: 1,
                                                                trailing: spacing + 1)
            }
            
            func addHeader(offset: CGPoint = .zero) {
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                        heightDimension: .absolute(sectionHeaderHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top,
                                                                         absoluteOffset: offset)
                section.boundarySupplementaryItems.append(header)
            }
            
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
                                                                                                           heightDimension: .fractionalHeight(DomainsCollectionUICache.shared.cardFractionalHeight())),
                                                                        subitems: [leadingItem])
                section = NSCollectionLayoutSection(group: containerGroup)
                section.contentInsets = .init(top: 0, leading: 24,
                                              bottom: 8, trailing: 24)
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
            case .emptySeparator(_, let height):
                addFooter(size: height)
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
            }
            
            return section
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

extension DomainsCollectionCarouselItemViewController {
    enum Section: Hashable {
        case domainsCarousel
        case recentActivity(numberOfActivities: Int)
        case noRecentActivities
        case dashesSeparator(id: UUID = .init(), height: CGFloat)
        case tutorialDashesSeparator(id: UUID = .init(), height: CGFloat)
        case emptySeparator(id: UUID = .init(), height: CGFloat)

        var title: String {
            switch self {
            case .recentActivity:
                return String.Constants.connectedAppsTitle.localized()
            case .domainsCarousel, .noRecentActivities, .dashesSeparator, .tutorialDashesSeparator, .emptySeparator:
                return ""
            }
        }
        
        var headerHeight: CGFloat {
            switch self {
            case .recentActivity:
                return DomainsCollectionSectionHeader.height
            case .dashesSeparator(_, let height), .tutorialDashesSeparator(_, let height), .emptySeparator(_, let height):
                return height
            case .domainsCarousel, .noRecentActivities:
                return 0
            }
        }
    }
    
    enum Item: Hashable {
        case domainCard(configuration: DomainCardConfiguration)
        case recentActivity(configuration: RecentActivitiesConfiguration)
        case noRecentActivities(configuration: NoRecentActivitiesConfiguration)
    }
    
    struct DomainCardConfiguration: Hashable {
        let id: UUID
        let domain: DomainDisplayInfo
        let availableActions: [Self.Action]
        let actionButtonPressedCallback: EmptyCallback
        
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
            case copyDomain(callback: EmptyCallback)
            case viewVault(vaultName: String, vaultAddress: String, callback: EmptyCallback)
            case setUpRR(isEnabled: Bool, callback: EmptyCallback)
            case rearrange(callback: EmptyCallback)
            
            var title: String {
                switch self {
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
                case .copyDomain, .setUpRR, .rearrange:
                    return nil
                case .viewVault(_, let vaultAddress, _):
                    return vaultAddress.walletAddressTruncated
                }
            }
            
            var icon: UIImage {
                switch self {
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
                }
            }
        }
    }
    
    struct RecentActivitiesConfiguration: Hashable {
        private let appHolder: UnifiedConnectedAppInfoHolder
        let availableActions: [Self.Action]
        let actionButtonPressedCallback: EmptyCallback
        
        var connectedApp: any UnifiedConnectAppInfoProtocol { appHolder.app }

        init(connectedApp: any UnifiedConnectAppInfoProtocol, availableActions: [DomainsCollectionCarouselItemViewController.RecentActivitiesConfiguration.Action], actionButtonPressedCallback: @escaping EmptyCallback) {
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
            case disconnect(callback: EmptyCallback)
            var title: String {
                switch self {
                case .disconnect:
                    return String.Constants.disconnect.localized()
                }
            }
            
            var subtitle: String? {
                switch self {
                case .disconnect:
                    return nil
                }
            }
            
            var icon: UIImage {
                switch self {
                case .disconnect:
                    return .systemMultiplyCircle
                }
            }
            
            static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.disconnect, .disconnect):
                    return true
                }
            }
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .disconnect:
                    hasher.combine(0)
                }
            }
        }
    }
    
    struct NoRecentActivitiesConfiguration: Hashable {
        let id = UUID()
        var learnMoreButtonPressedCallback: EmptyCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    enum Action {
        case recentActivityLearnMore
        case domainSelected(_ domain: DomainDisplayInfo)
        case domainNameCopied
        case rearrangeDomains
    }
}
