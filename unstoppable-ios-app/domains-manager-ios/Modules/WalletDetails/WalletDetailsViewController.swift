//
//  WalletDetailsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.05.2022.
//

import UIKit

@MainActor
protocol WalletDetailsViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: WalletDetailsSnapshot, animated: Bool)
    func set(title: String?)
}

typealias WalletDetailsDataSource = UICollectionViewDiffableDataSource<WalletDetailsViewController.Section, WalletDetailsViewController.Item>
typealias WalletDetailsSnapshot = NSDiffableDataSourceSnapshot<WalletDetailsViewController.Section, WalletDetailsViewController.Item>

@MainActor
final class WalletDetailsViewController: BaseViewController, TitleVisibilityAfterLimitNavBarScrollingBehaviour, BlurVisibilityAfterLimitNavBarScrollingBehaviour {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [WalletDetailsListCell.self, WalletDetailsTopInfoCell.self] }
    var presenter: WalletDetailsViewPresenterProtocol!
    override var scrollableContentYOffset: CGFloat? { 8 }
    override var analyticsName: Analytics.ViewName { .walletDetails }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.wallet: presenter.walletAddress] }
    override var navBackStyle: BaseViewController.NavBackIconStyle { currentNavBackStyle }
    var currentNavBackStyle: BaseViewController.NavBackIconStyle = .arrow

    private var dataSource: WalletDetailsDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cNavigationController?.navigationBar.navBarContentView.setTitle(hidden: true, animated: false)
        presenter.viewDidAppear()
    }
    
    override func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? {
        { [weak self, weak navBar] in
            guard let navBar = navBar else { return }
            
            self?.updateBlurVisibility(for: yOffset, in: navBar)
            self?.updateTitleVisibility(for: yOffset, in: navBar, limit: 145)
        }
    }
}

// MARK: - NewWalletDetailsViewProtocol
extension WalletDetailsViewController: WalletDetailsViewProtocol {
    func applySnapshot(_ snapshot: WalletDetailsSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    func set(title: String?) {
        cNavigationController?.navigationBar.set(title: title)
    }
}

// MARK: - UICollectionViewDelegate
extension WalletDetailsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Setup methods
private extension WalletDetailsViewController {
    func setup() {
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.accessibilityIdentifier = "Wallet Details Collection View"
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 41

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = WalletDetailsDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .topInfo(let topInfo):
                let cell = collectionView.dequeueCellOfType(WalletDetailsTopInfoCell.self, forIndexPath: indexPath)
                
                cell.setWith(walletInfo: topInfo.walletInfo,
                             domain: topInfo.domain,
                             isUpdating: topInfo.isUpdating)
                cell.copyAddressButtonPressedCallback = topInfo.copyButtonPressed
                cell.externalBadgePressedCallback = topInfo.externalBadgePressed
                
                return cell
            case .listItem(let item):
                let cell = collectionView.dequeueCellOfType(WalletDetailsListCell.self, forIndexPath: indexPath)
                
                cell.setWith(item: item)
                
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
                layoutSection = .listItemSection(height: 200)
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
extension WalletDetailsViewController {
    enum Section: Int, Hashable {
        case topInfo, backUpAndRecovery, renameAndDomains, removeWallet
    }
    
    enum Item: Hashable {
        case topInfo(_ topInfo: WalletDetailsTopInfo)
        case listItem(_ item: WalletDetailsListItem)
    }
    
    struct WalletDetailsTopInfo: Hashable {
        let walletInfo: WalletDisplayInfo
        let domain: DomainDisplayInfo?
        let isUpdating: Bool
        let copyButtonPressed: EmptyCallback
        let externalBadgePressed: EmptyCallback
        
        static func == (lhs: WalletDetailsViewController.WalletDetailsTopInfo, rhs: WalletDetailsViewController.WalletDetailsTopInfo) -> Bool {
            lhs.walletInfo == rhs.walletInfo && lhs.domain == rhs.domain && lhs.isUpdating == rhs.isUpdating
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(walletInfo)
            hasher.combine(domain)
            hasher.combine(isUpdating)
        }
    }
    
    enum WalletDetailsListItem: Hashable {
        case backUp(state: WalletDisplayInfo.BackupState, isOnline: Bool)
        case recoveryPhrase(recoveryType: UDWallet.RecoveryType)
        case rename
        case domains(domainsCount: Int, walletName: String)
        case removeWallet(isConnected: Bool, walletName: String)
        case reverseResolution(state: ReverseResolutionState)
        case importWallet
       
        var title: String {
            switch self {
            case .backUp(let state, _):
                if case .backedUp = state {
                    return String.Constants.backedUpToICloud.localized()
                }
                return String.Constants.backUpToICloud.localized()
            case .recoveryPhrase(let recoveryType):
                switch recoveryType {
                case .privateKey:
                    return String.Constants.viewPrivateKey.localized()
                case .recoveryPhrase:
                    return String.Constants.viewRecoveryPhrase.localized()
                }
            case .rename:
                return String.Constants.rename.localized()
            case .domains(let domainsCount, let walletName):
                let domainsPlural = String.Constants.pluralNDomains.localized(domainsCount, domainsCount)
                return String.Constants.seeDomainsStoredInWallet.localized(domainsPlural, walletName.lowercased())
            case .removeWallet(let isConnected, let walletName):
                return isConnected ? String.Constants.disconnectWallet.localized() : String.Constants.removeWallet.localized(walletName.lowercased())
            case .reverseResolution(let state):
                switch state {
                case .notSet:
                    return String.Constants.setupReverseResolution.localized()
                case .setFor, .settingFor:
                    return String.Constants.reverseResolution.localized()
                }
            case .importWallet:
                return String.Constants.importWallet.localized()
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .backUp(let state, _):
                if case .backedUp = state {
                    return state.tintColor
                }
                return .foregroundAccent
            case .recoveryPhrase:
                return .foregroundSecondary
            case .rename, .domains, .reverseResolution, .importWallet:
                return .foregroundAccent
            case .removeWallet:
                return .foregroundDanger
            }
        }
        
        var icon: UIImage {
            switch self {
            case .backUp(let state, _):
                if case .backedUp = state {
                    return state.icon
                }
                return .cloudIcon
            case .recoveryPhrase:
                return .recoveryPhraseIcon
            case .rename:
                return .penIcon
            case .domains:
                return .domainsListIcon
            case .removeWallet:
                return .stopIcon
            case .reverseResolution(let state):
                switch state {
                case .settingFor:
                    return .refreshIcon
                case .notSet, .setFor:
                    return .reverseResolutionArrows
                }
            case .importWallet:
                return .recoveryPhraseIcon
            }
        }
        
        enum ReverseResolutionState: Hashable {
            case notSet(isEnabled: Bool)
            case settingFor(domain: DomainDisplayInfo)
            case setFor(domain: DomainDisplayInfo, isEnabled: Bool, isUpdatingRecords: Bool)
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .backUp:
                return .walletBackup
            case .recoveryPhrase:
                return .walletRecoveryPhrase
            case .rename:
                return .walletRename
            case .domains:
                return .walletDomainsList
            case .removeWallet:
                return .walletRemove
            case .reverseResolution:
                return .walletReverseResolution
            case .importWallet:
                return .importWallet
            }
        }
    }
    
}
