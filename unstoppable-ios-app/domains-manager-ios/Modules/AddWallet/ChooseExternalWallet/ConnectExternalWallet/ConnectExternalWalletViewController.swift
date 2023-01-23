//
//  ConnectExternalWalletViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.09.2022.
//

import UIKit

@MainActor
protocol ConnectExternalWalletViewProtocol: BaseCollectionViewControllerProtocol & ViewWithDashesProgress {
    func applySnapshot(_ snapshot: ConnectExternalWalletSnapshot, animated: Bool)
}

typealias ConnectExternalWalletDataSource = UICollectionViewDiffableDataSource<ConnectExternalWalletViewController.Section, ConnectExternalWalletViewController.Item>
typealias ConnectExternalWalletSnapshot = NSDiffableDataSourceSnapshot<ConnectExternalWalletViewController.Section, ConnectExternalWalletViewController.Item>

@MainActor
final class ConnectExternalWalletViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [ConnectExternalWalletCell.self, CollectionViewHeaderCell.self] }
    var presenter: ConnectExternalWalletViewPresenterProtocol!
    private var dataSource: ConnectExternalWalletDataSource!
    override var prefersLargeTitles: Bool { true }
    override var navBackStyle: NavBackIconStyle { presenter.navBackStyle }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var scrollableContentYOffset: CGFloat? { 64 }
    override var largeTitleAlignment: NSTextAlignment { .center }

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

// MARK: - ConnectExternalWalletViewProtocol
extension ConnectExternalWalletViewController: ConnectExternalWalletViewProtocol {
    var progress: Double? { 0.5 }

    func applySnapshot(_ snapshot: ConnectExternalWalletSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension ConnectExternalWalletViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Private functions
private extension ConnectExternalWalletViewController {
    @objc func applicationWillEnterForeground() {
        presenter.applicationWillEnterForeground()
    }
}

// MARK: - Setup functions
private extension ConnectExternalWalletViewController {
    func setup() {
        setupUI()
        setupCollectionView()
        addProgressDashesView()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    func setupUI() {
        title = String.Constants.chooseExternalWalletTitle.localized()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(CollectionTextHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier)
        collectionView.contentInset.top = 107

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ConnectExternalWalletDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .externalWallet(let description):
                let cell = collectionView.dequeueCellOfType(ConnectExternalWalletCell.self, forIndexPath: indexPath)
                
                cell.setWith(walletRecord: description.walletRecord, isInstalled: description.isInstalled)
                
                return cell
            case .header:
                let cell = collectionView.dequeueCellOfType(CollectionViewHeaderCell.self, forIndexPath: indexPath)
                cell.setTitle(nil,
                              subtitleDescription: .init(subtitle: String.Constants.chooseExternalWalletSubtitle.localized()),
                              icon: nil)
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                       withReuseIdentifier: CollectionTextHeaderReusableView.reuseIdentifier,
                                                                       for: indexPath) as! CollectionTextHeaderReusableView
            
            if let section = self?.section(at: indexPath),
               case .labeled(let header) = section {
                view.setHeader(header)
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
            let sectionHeaderHeight = section?.headerHeight ?? 0

            let layoutSection: NSCollectionLayoutSection
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            func addBackground() {
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                background.contentInsets.top = sectionHeaderHeight
                layoutSection.decorationItems = [background]
            }
            
            switch section {
            case .labeled:
                addBackground()
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(sectionHeaderHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            case .single:
                addBackground()
            case .header, .none:
                Void()
            }
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ConnectExternalWalletViewController {
    enum Section: Hashable {
        case header, single, labeled(header: String)
        
        var headerHeight: CGFloat {
            switch self {
            case .labeled:
                return CollectionTextHeaderReusableView.Height
            case .single, .header:
                return 0
            }
        }
    }
    
    enum Item: Hashable {
        case externalWallet(_ description: ExternalWalletDescription), header
    }
    
    struct ExternalWalletDescription: Hashable {
        let walletRecord: WCWalletsProvider.WalletRecord
        let isInstalled: Bool
    }
}
