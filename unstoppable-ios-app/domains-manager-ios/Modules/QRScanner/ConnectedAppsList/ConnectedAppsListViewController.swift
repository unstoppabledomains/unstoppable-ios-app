//
//  ConnectedAppsListViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.06.2022.
//

import UIKit

@MainActor
protocol ConnectedAppsListViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ConnectedAppsListSnapshot, animated: Bool)
}

typealias ConnectedAppsListDataSource = UICollectionViewDiffableDataSource<ConnectedAppsListViewController.Section, ConnectedAppsListViewController.Item>
typealias ConnectedAppsListSnapshot = NSDiffableDataSourceSnapshot<ConnectedAppsListViewController.Section, ConnectedAppsListViewController.Item>

@MainActor
final class ConnectedAppsListViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [ConnectedAppCell.self,
                                                        ConnectedAppsEmptyCell.self] }
    var presenter: ConnectedAppsListViewPresenterProtocol!
    private var dataSource: ConnectedAppsListDataSource!
    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .wcConnectedAppsList }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
  
}

// MARK: - ConnectedAppsListViewProtocol
extension ConnectedAppsListViewController: ConnectedAppsListViewProtocol {
    func applySnapshot(_ snapshot: ConnectedAppsListSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension ConnectedAppsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}

// MARK: - Private functions
private extension ConnectedAppsListViewController {

}

// MARK: - Setup functions
private extension ConnectedAppsListViewController {
    func setup() {
        setupCollectionView()
        title = String.Constants.connectedAppsTitle.localized()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 16
        collectionView.register(CollectionTextHeaderReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier)
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ConnectedAppsListDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .app(let displayInfo, let actionCallback):
                let cell = collectionView.dequeueCellOfType(ConnectedAppCell.self, forIndexPath: indexPath)
                
                cell.setWith(displayInfo: displayInfo, actionCallback: actionCallback)
                
                return cell
            case .emptyState(let callback):
                let cell = collectionView.dequeueCellOfType(ConnectedAppsEmptyCell.self, forIndexPath: indexPath)
                cell.set(actionCallback: callback)
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            guard let section = self?.section(at: indexPath) else { return nil }
            
            switch section {
            case .walletApps(let walletName):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier,
                                                                           for: indexPath) as! CollectionTextHeaderReusableView
                view.setHeader(walletName)
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
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))

            switch section {
            case .walletApps:
                layoutSection = .flexibleListItemSection()
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                      leading: spacing + 1,
                                                                      bottom: 1,
                                                                      trailing: spacing + 1)
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(CollectionTextHeaderReusableView.Height))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
                
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                background.contentInsets.top = CollectionTextHeaderReusableView.Height
                layoutSection.decorationItems = [background]
            case .emptyState, .none:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .zero
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .fractionalHeight(0.9)),
                    subitems: [item])
                layoutSection = NSCollectionLayoutSection(group: containerGroup)
            }
            
            return layoutSection
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

typealias ConnectedAppCellItemActionCallback = @Sendable @MainActor (ConnectedAppsListViewController.ItemAction)->()

// MARK: - Collection elements
extension ConnectedAppsListViewController {
    enum Section: Hashable {
        case walletApps(walletName: String)
        case emptyState
    }
    
    enum Item: Hashable, Sendable {
        case app(_ displayInfo: AppItemDisplayInfo, actionCallback: ConnectedAppCellItemActionCallback)
        case emptyState(scanCallback: MainActorAsyncCallback)
        
        static func == (lhs: ConnectedAppsListViewController.Item, rhs: ConnectedAppsListViewController.Item) -> Bool {
            switch (lhs, rhs) {
            case (.app(let lhsDisplayInfo, _), .app(let rhsDisplayInfo, _)):
                return lhsDisplayInfo == rhsDisplayInfo
            case (.emptyState, .emptyState):
                return true
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .app(let displayInfo, _):
                hasher.combine(displayInfo)
            case .emptyState:
                hasher.combine(0)
            }
        }
        
        var appName: String {
            switch self {
            case .app(let displayInfo, _):
                return displayInfo.app.appName
            case .emptyState:
                return ""
            }
        }
    }
    
    struct AppItemDisplayInfo: Hashable, Sendable {
        private let appHolder: UnifiedConnectedAppInfoHolder
        let domain: DomainDisplayInfo
        let blockchainTypes: NonEmptyArray<BlockchainType>
        let actions: [ItemAction]
        var app: any UnifiedConnectAppInfoProtocol { appHolder.app }
        
        init(app: any UnifiedConnectAppInfoProtocol,
             domain: DomainDisplayInfo,
             blockchainTypes: NonEmptyArray<BlockchainType>,
             actions: [ConnectedAppsListViewController.ItemAction]) {
            self.appHolder = .init(app: app)
            self.domain = domain
            self.blockchainTypes = blockchainTypes
            self.actions = actions
        }
    }
    
    enum ItemAction: Hashable {
        case domainInfo(domain: DomainDisplayInfo)
        case networksInfo(networks: [String])
        case disconnect
        
        var title: String {
            switch self {
            case .domainInfo(let domain):
                return domain.name
            case .networksInfo:
                return String.Constants.supportedNetworks.localized()
            case .disconnect:
                return String.Constants.disconnect.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .domainInfo:
                return String.Constants.connected.localized()
            case .networksInfo(let networks):
                return networks.joined(separator: ", ")
            case .disconnect:
                return nil
            }
        }
        
        var icon: UIImage {
            get async {
                switch self {
                case .domainInfo(let domain):
                    return await UIMenuDomainAvatarLoader.menuAvatarFor(domain: domain) ?? .systemGlobe
                case .networksInfo:
                    return .systemGlobe
                case .disconnect:
                    return .systemMultiplyCircle
                }
            }
        }
        
        var analyticName: Analytics.Button {
            switch self {
            case .domainInfo:
                return .connectedAppDomain
            case .networksInfo:
                return .connectedAppSupportedNetworks
            case .disconnect:
                return .disconnectApp
            }
        }
    }
}

import SwiftUI
struct ConnectedAppsListViewControllerWrapper: UIViewControllerRepresentable {
    
    var scanCallback: EmptyCallback?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UDRouter().buildConnectedAppsModule(scanCallback: scanCallback)
        let nav = EmptyRootCNavigationController(rootViewController: vc)
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}

@available(iOS 17, *)
#Preview {
    ConnectedAppsListViewControllerWrapper()
        .ignoresSafeArea()
}
