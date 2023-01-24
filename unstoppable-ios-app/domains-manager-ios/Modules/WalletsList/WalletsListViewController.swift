//
//  WalletsListViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

@MainActor
protocol WalletsListViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: WalletsListSnapshot, animated: Bool)
}

typealias WalletsListDataSource = UICollectionViewDiffableDataSource<WalletsListViewController.Section, WalletsListViewController.Item>
typealias WalletsListSnapshot = NSDiffableDataSourceSnapshot<WalletsListViewController.Section, WalletsListViewController.Item>

@MainActor
final class WalletsListViewController: BaseViewController {
    

    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [WalletsListCell.self] }
    var presenter: WalletsListViewPresenterProtocol!
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var scrollableContentYOffset: CGFloat? { 36 }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    private var dataSource: WalletsListDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
    }
    
}

// MARK: - WalletsListViewProtocol
extension WalletsListViewController: WalletsListViewProtocol {
    func applySnapshot(_ snapshot: WalletsListSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension WalletsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - InteractivePushNavigation
extension WalletsListViewController: CNavigationControllerChildTransitioning {
    func popNavBarAnimatedTransitioning(to viewController: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if cNavigationController?.viewControllers.first(where: { $0 is SettingsViewController }) != nil {
            return BackToSettingsNavBarPopAnimation(animationDuration: CNavigationHelper.DefaultNavAnimationDuration)
        }
        return nil
    }
}

// MARK: - Private functions
private extension WalletsListViewController {
    @objc func didPressAddButton() {
        logButtonPressedAnalyticEvents(button: .plus)
        UDVibration.buttonTap.vibrate()
        presenter.didPressAddButton()
    }
}

// MARK: - Setup methods
private extension WalletsListViewController {
    func setup() {
        setupNavBar()
        setupCollectionView()
    }
    
    func setupNavBar() {
        self.title = presenter.title
        
        if presenter.canAddWallet {
            let addButton = UIBarButtonItem(image: .plusIconNav, style: .plain, target: self, action: #selector(didPressAddButton))
            addButton.tintColor = .foregroundDefault
            addButton.accessibilityIdentifier = "Wallets List Plus Button"
            navigationItem.rightBarButtonItem = addButton            
        }
    }
    
    func setupCollectionView() {
        collectionView.accessibilityIdentifier = "Wallets List Collection View"
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(WalletsListHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: WalletsListHeaderView.reuseIdentifier)
        collectionView.contentInset.top = 45
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = WalletsListDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            let cell = collectionView.dequeueCellOfType(WalletsListCell.self, forIndexPath: indexPath)
            
            cell.setWith(item: item)
          
            return cell
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                       withReuseIdentifier: WalletsListHeaderView.reuseIdentifier,
                                                                       for: indexPath) as! WalletsListHeaderView
            
            if let section = self?.section(at: indexPath) {
                view.setHeader(for: section)
            }
            
            return view
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
            let layoutSection = NSCollectionLayoutSection.listItemSection(height: section?.itemHeight ?? 0)
            var sectionHeaderHeight = section?.headerHeight ?? 0
            if sectionIndex == 0 {
                sectionHeaderHeight += WalletsListHeaderView.topOffset
            }
            
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            background.contentInsets.top = sectionHeaderHeight
            layoutSection.decorationItems = [
                background
            ]
            
            switch section {
            case .connected, .managed, .manageICloudExtraHeight:
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                        heightDimension: .absolute(sectionHeaderHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            case .manageICLoud, .none:
                Void()
            }

            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)

        return layout
    }
}

// MARK: - WalletInfo
extension WalletsListViewController {
 
}

extension WalletsListViewController {
    enum Section: Hashable {
        case managed(numberOfItems: Int), manageICLoud, manageICloudExtraHeight, connected(numberOfItems: Int)
        
        var headerHeight: CGFloat {
            switch self {
            case .managed, .connected:
                return WalletsListHeaderView.Height
            case .manageICloudExtraHeight:
                return 32
            case .manageICLoud:
                return 0
            }
        }
        
        var itemHeight: CGFloat {
            switch self {
            case .managed, .connected:
                return BaseListCollectionViewCell.height
            case .manageICLoud, .manageICloudExtraHeight:
                return 56
            }
        }
        
        var headerTitle: String {
            switch self {
            case .managed:
                return String.Constants.managed.localized()
            case .connected:
                return String.Constants.connected.localized()
            case .manageICLoud, .manageICloudExtraHeight:
                return ""
            }
        }
    }
    
    enum Item: Hashable {
        case walletInfo(_ walletInfo: WalletDisplayInfo)
        case selectableWalletInfo(_ walletInfo: WalletDisplayInfo, isSelected: Bool)
        case manageICloudBackups
    }
}
