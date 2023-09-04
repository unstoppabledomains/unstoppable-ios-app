//
//  DomainsCollectionEmptyStateView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2022.
//

import UIKit

typealias DomainsCollectionEmptyViewDataSource = UICollectionViewDiffableDataSource<DomainsCollectionEmptyStateView.Section, DomainsCollectionEmptyStateView.Item>
typealias DomainsCollectionEmptyViewSnapshot = NSDiffableDataSourceSnapshot<DomainsCollectionEmptyStateView.Section, DomainsCollectionEmptyStateView.Item>

protocol DomainsCollectionEmptyStateViewDelegate: AnyObject {
    func didTapEmptyListItemOf(itemType: DomainsCollectionEmptyStateView.EmptyListItemType)
}

final class DomainsCollectionEmptyStateView: UIView {
    
    private var collectionView: UICollectionView!
    private var dataSource: DomainsCollectionEmptyViewDataSource!
    weak var delegate: DomainsCollectionEmptyStateViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - UICollectionViewDelegate
extension DomainsCollectionEmptyStateView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .emptyTopInfo:
            return
        case .emptyList(let itemType):
            delegate?.didTapEmptyListItemOf(itemType: itemType)
        }
    }
}

// MARK: - Setup methods
private extension DomainsCollectionEmptyStateView {
    func setup() {
        backgroundColor = .clear
        setupCollectionView()
        prepareSnapshot()
    }
    
    func setupCollectionView() {
        createCollectionView()
        collectionView.registerCellNibOfType(DomainsCollectionEmptyListCell.self)
        collectionView.registerCellNibOfType(DomainsCollectionEmptyTopInfoCell.self)
        
        switch deviceSize {
        case .i4Inch:
            collectionView.contentInset.top = 37
        case .i4_7Inch:
            collectionView.contentInset.top = 57
        default:
            collectionView.contentInset.top = 82
        }
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        configureDataSource()
    }
    
    func createCollectionView() {
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: buildLayout())
        addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configureDataSource() {
        dataSource = DomainsCollectionEmptyViewDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .emptyList(let item):
                let cell = collectionView.dequeueCellOfType(DomainsCollectionEmptyListCell.self, forIndexPath: indexPath)
                cell.setWith(item: item)
                
                return cell
            case .emptyTopInfo:
                let cell = collectionView.dequeueCellOfType(DomainsCollectionEmptyTopInfoCell.self, forIndexPath: indexPath)
                
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
            
            let section = NSCollectionLayoutSection.flexibleListItemSection(height: 88)
            
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            section.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                            leading: spacing + 1,
                                                            bottom: 1,
                                                            trailing: spacing + 1)
            if sectionIndex != 0 {
                section.decorationItems = [background]
            }
            
            
            return section
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
    
    func prepareSnapshot() {
        var snapshot = DomainsCollectionEmptyViewSnapshot()
        
        snapshot.appendSections([.emptyTopInfo])
        snapshot.appendItems([.emptyTopInfo])
        snapshot.appendSections([.emptyList(item: .importWallet)])
        snapshot.appendItems([.emptyList(item: .importWallet)])
        snapshot.appendSections([.emptyList(item: .external)])
        snapshot.appendItems([.emptyList(item: .external)])
        
        dataSource.apply(snapshot)
    }
}

extension DomainsCollectionEmptyStateView {
    enum Section: Hashable {
        case search, primary, other, minting, searchEmptyState, emptyTopInfo, emptyList(item: EmptyListItemType)
    }
    
    enum Item: Hashable {
        case emptyList(item: EmptyListItemType)
        case emptyTopInfo
    }
    
    enum EmptyListItemType: Hashable, CaseIterable {
        case importWallet, external
        
        var title: String {
            switch self {
            case .importWallet:
                return String.Constants.domainsCollectionEmptyStateImportTitle.localized()
            case .external:
                return String.Constants.domainsCollectionEmptyStateExternalTitle.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .importWallet:
                return String.Constants.domainsCollectionEmptyStateImportSubtitle.localized()
            case .external:
                return String.Constants.domainsCollectionEmptyStateExternalSubtitle.localized()
            }
        }
        
        var icon: UIImage {
            switch self {
            case .importWallet:
                return .recoveryPhraseIcon
            case .external:
                return .externalWalletIndicator
            }
        }
        
        var analyticsName: Analytics.Button {
            switch self {
            case .importWallet:
                return .mintDomains
            case .external:
                return .manageDomains
            }
        }
    }
}
