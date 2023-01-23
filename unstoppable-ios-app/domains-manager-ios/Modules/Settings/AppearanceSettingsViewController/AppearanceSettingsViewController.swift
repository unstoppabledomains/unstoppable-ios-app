//
//  AppearanceSettingsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import UIKit

@MainActor
protocol AppearanceSettingsViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: AppearanceSettingsSnapshot, animated: Bool)
}

typealias AppearanceSettingsDataSource = UICollectionViewDiffableDataSource<AppearanceSettingsViewController.Section, AppearanceSettingsViewController.Item>
typealias AppearanceSettingsSnapshot = NSDiffableDataSourceSnapshot<AppearanceSettingsViewController.Section, AppearanceSettingsViewController.Item>

@MainActor
final class AppearanceSettingsViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [AppearanceSettingsCell.self] }
    var presenter: AppearanceSettingsViewPresenterProtocol!
    private var dataSource: AppearanceSettingsDataSource!

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
}

// MARK: - AppearanceSettingsViewProtocol
extension AppearanceSettingsViewController: AppearanceSettingsViewProtocol {
    func applySnapshot(_ snapshot: AppearanceSettingsSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}


// MARK: - UICollectionViewDelegate
extension AppearanceSettingsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}


// MARK: - Setup functions
private extension AppearanceSettingsViewController {
    func setup() {
        setupCollectionView()
        setupNavBar()
    }
    
    func setupNavBar() {
        self.title = String.Constants.settingsAppearance.localized()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(EmptyCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: EmptyCollectionReusableView.reuseIdentifier)
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = AppearanceSettingsDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .theme:
                let cell = collectionView.dequeueCellOfType(AppearanceSettingsCell.self, forIndexPath: indexPath)
                cell.setWith(item: item)
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: EmptyCollectionReusableView.reuseIdentifier, for: indexPath)
        }
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection = .flexibleListItemSection()
            
            
            
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            
            if sectionIndex == 0 {
                let headerHeight: CGFloat = 33
                background.contentInsets.top = headerHeight
                
                let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .absolute(headerHeight))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: size,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
            }
            
            
            layoutSection.decorationItems = [background]
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

extension AppearanceSettingsViewController {
    enum Section: Hashable {
        case theme
    }
    
    enum Item: Hashable {
        case theme(_ value: UIUserInterfaceStyle)
    }
}
