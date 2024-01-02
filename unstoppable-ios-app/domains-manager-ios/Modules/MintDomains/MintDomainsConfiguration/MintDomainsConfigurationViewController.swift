//
//  MintDomainsConfigurationViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.05.2022.
//

import UIKit

@MainActor
protocol MintDomainsConfigurationViewProtocol: BaseCollectionViewControllerProtocol & ViewWithDashesProgress {
    func applySnapshot(_ snapshot: MintDomainsConfigurationSnapshot, animated: Bool)
    func setWalletInfo(_ walletInfo: WalletDisplayInfo, canSelect: Bool)
    func setMintButtonEnabled(_ isEnabled: Bool)
    func setLoadingIndicator(active: Bool)
    func setMintingLimitReached(visible: Bool, limit: Int)
}

typealias MintDomainsConfigurationDataSource = UICollectionViewDiffableDataSource<MintDomainsConfigurationViewController.Section, MintDomainsConfigurationViewController.Item>
typealias MintDomainsConfigurationSnapshot = NSDiffableDataSourceSnapshot<MintDomainsConfigurationViewController.Section, MintDomainsConfigurationViewController.Item>

@MainActor
final class MintDomainsConfigurationViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var walletIndicatorView: ResizableRoundedWalletImageView!
    @IBOutlet private weak var mintDomainsToLabel: UILabel!
    @IBOutlet private weak var gradientView: UDGradientCoverView!
    @IBOutlet private weak var walletSelectorButton: SelectorButton!
    @IBOutlet private weak var mintDomainsButton: MainButton!
    @IBOutlet private weak var mintDomainsWarningIndicator: UIImageView!

    var cellIdentifiers: [UICollectionViewCell.Type] { [MintDomainsConfigurationSelectionCell.self,
                                                        MintDomainsConfigurationCardCell.self,
                                                        CollectionViewHeaderCell.self] }
    var presenter: MintDomainsConfigurationViewPresenterProtocol!
    private var dataSource: MintDomainsConfigurationDataSource!
    override var prefersLargeTitles: Bool { true }
    override var largeTitleAlignment: NSTextAlignment { .center }
    override var scrollableContentYOffset: CGFloat? { 80 }
    override var analyticsName: Analytics.ViewName { .mintDomainsConfiguration }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let gradientCoverHeight = view.bounds.height - gradientView.frame.minY
        collectionView.contentInset.bottom = 32 + gradientCoverHeight
    }
    
}

// MARK: - MintDomainsConfigurationViewProtocol
extension MintDomainsConfigurationViewController: MintDomainsConfigurationViewProtocol {
    var progress: Double? { presenter.progress }
    
    func applySnapshot(_ snapshot: MintDomainsConfigurationSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            self.collectionView.isScrollEnabled = (self.collectionView.contentSize.height + self.collectionView.contentInset.top) > (self.collectionView.bounds.height - self.collectionView.contentInset.bottom)
        }
    }
    
    func setWalletInfo(_ walletInfo: WalletDisplayInfo, canSelect: Bool) {
        walletIndicatorView.setWith(walletInfo: walletInfo, style: .extraSmall)
        walletSelectorButton.setTitle(walletInfo.displayName, image: nil)
        walletSelectorButton.setSelectorEnabled(canSelect)
    }
    
    func setMintButtonEnabled(_ isEnabled: Bool) {
        mintDomainsButton.isEnabled = isEnabled
    }
    
    func setLoadingIndicator(active: Bool) {
        mintDomainsButton.isUserInteractionEnabled = !active
        if active {
            mintDomainsButton.showLoadingIndicator()
        } else {
            mintDomainsButton.hideLoadingIndicator()
        }
    }
    
    func setMintingLimitReached(visible: Bool, limit: Int) {
        mintDomainsWarningIndicator.isHidden = !visible
        if visible {
            mintDomainsToLabel.setAttributedTextWith(text: String.Constants.moveDomainsAmountLimitMessage.localized(limit) + ":",
                                                     font: .currentFont(withSize: 16, weight: .medium),
                                                     textColor: .foregroundWarning,
                                                     lineBreakMode: .byTruncatingTail)
        } else {
            mintDomainsToLabel.setAttributedTextWith(text: String.Constants.pluralMoveDomainsTo.localized(presenter.domainsCount) + ":",
                                                     font: .currentFont(withSize: 16, weight: .medium),
                                                     textColor: .foregroundSecondary,
                                                     lineBreakMode: .byTruncatingTail)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension MintDomainsConfigurationViewController: UICollectionViewDelegate {
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
private extension MintDomainsConfigurationViewController {
    @IBAction func walletSelectorButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .selectWallet)
        presenter.walletSelectorButtonPressed()
    }
    
    @IBAction func mintDomainsButtonPressed(_ sender: Any) {
        presenter.mintDomainsButtonPressed()
    }
}

// MARK: - Setup functions
private extension MintDomainsConfigurationViewController {
    func setup() {
        addProgressDashesView()
        setupCollectionView()
        localizeContent()
        walletSelectorButton.customTitleEdgePadding = 0
    }
    
    func localizeContent() {
        let domainsCount = presenter.domainsCount
        
        if domainsCount > 1 {
            mintDomainsButton.setTitle(String.Constants.moveSelectedDomains.localized(), image: nil)
        } else {
            mintDomainsButton.setTitle(String.Constants.moveDomains.localized(), image: nil)
        }
        title = presenter.title
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(MintDomainsConfigurationListHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: MintDomainsConfigurationListHeaderView.reuseIdentifier)
        collectionView.contentInset.top = 107

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = MintDomainsConfigurationDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .domainListItem(let configuration):
                let cell = collectionView.dequeueCellOfType(MintDomainsConfigurationSelectionCell.self, forIndexPath: indexPath)
                
                cell.setWith(configuration: configuration)
                return cell
            case .domainCard(let domainName):
                let cell = collectionView.dequeueCellOfType(MintDomainsConfigurationCardCell.self, forIndexPath: indexPath)
                cell.setWith(domainName: domainName)
                return cell
            case .header(let domainsCount):
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                cell.setTitle(String.Constants.pluralMoveDomains.localized(domainsCount),
                              subtitleDescription: nil,
                              icon: nil)
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let section = self?.section(at: indexPath) else { return nil }

            switch section {
            case .domainsList(let domainsCount, let isAllSelected, let selectAllButtonCallback):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: MintDomainsConfigurationListHeaderView.reuseIdentifier,
                                                                           for: indexPath) as! MintDomainsConfigurationListHeaderView
                view.setHeader(for: domainsCount, isAllSelected: isAllSelected, selectAllButtonCallback: selectAllButtonCallback)
                return view
            case .domainCard, .setPrimary, .header:
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
            @MainActor
            func addBackground() {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                background.contentInsets.top = section?.headerHeight ?? 0
                layoutSection.decorationItems = [background]
            }
            
            switch section {
            case .domainsList:
                addBackground()
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(section?.headerHeight ?? 0))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            case .setPrimary:
                addBackground()
            case .domainCard:
                let topOffset: CGFloat
                switch deviceSize {
                case .i4Inch, .i4_7Inch:
                    topOffset = 20
                default:
                    topOffset = 100
                }
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: topOffset,
                                                                      leading: 1,
                                                                      bottom: 1,
                                                                      trailing: 1)
            case .none, .header:
                Void()
            }
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension MintDomainsConfigurationViewController {
    enum Section: Hashable {
        case header
        case domainsList(domainsCount: Int, isAllSelected: Bool, selectAllButtonCallback: MainActorAsyncCallback)
        case domainCard
        case setPrimary
       
        var headerHeight: CGFloat {
            switch self {
            case .domainsList:
                return MintDomainsConfigurationListHeaderView.Height
            case .domainCard, .setPrimary, .header:
                return 0
            }
        }
        
        static func == (lhs: MintDomainsConfigurationViewController.Section, rhs: MintDomainsConfigurationViewController.Section) -> Bool {
            switch (lhs, rhs) {
            case (.domainsList(let lhsDomainsCount, let lhsIsAllSelected, _), .domainsList(let rhsDomainsCount, let rhsIsAllSelected, _)):
                return lhsDomainsCount == rhsDomainsCount && lhsIsAllSelected == rhsIsAllSelected
            case (.domainCard, .domainCard):
                return true
            case (.setPrimary, .setPrimary):
                return true
            case (.header, .header):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .domainsList(let domainsCount, let isAllSelected, _):
                hasher.combine(domainsCount)
                hasher.combine(isAllSelected)
            case .domainCard:
                hasher.combine(0)
            case .setPrimary:
                hasher.combine(1)
            case .header:
                hasher.combine(2)
            }
        }
    }
    
    enum Item: Hashable, Sendable {

        case domainListItem(configuration: ListItemConfiguration)
        case domainCard(_ domain: String)
        case header(domainsCount: Int)
        
        static func == (lhs: MintDomainsConfigurationViewController.Item, rhs: MintDomainsConfigurationViewController.Item) -> Bool {
            switch (lhs, rhs) {
            case (.domainListItem(let lhsItem), .domainListItem(let rhsItem)):
                return lhsItem == rhsItem
            case (.domainCard(let lhsDomain), .domainCard(let rhsDomain)):
                return lhsDomain == rhsDomain
            case (.header(let lhsDomainsCount), .header(let rhsDomainsCount)):
                return lhsDomainsCount == rhsDomainsCount
            default:
                return false
            }
        }
        func hash(into hasher: inout Hasher) {
            switch self {
            case .domainListItem(let item):
                hasher.combine(item)
            case .domainCard(let domain):
                hasher.combine(domain)
            case .header(let domainsCount):
                hasher.combine(domainsCount)
            }
        }
    }
    
    struct ListItemConfiguration: Hashable {
        let domain: String
        let isSelected: Bool
        let state: MintDomainsConfigurationSelectionCell.State
    }
}
