//
//  ParkedDomainsFoundViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import UIKit

@MainActor
protocol ParkedDomainsFoundViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ParkedDomainsFoundSnapshot, animated: Bool)
}

typealias ParkedDomainsFoundDataSource = UICollectionViewDiffableDataSource<ParkedDomainsFoundViewController.Section, ParkedDomainsFoundViewController.Item>
typealias ParkedDomainsFoundSnapshot = NSDiffableDataSourceSnapshot<ParkedDomainsFoundViewController.Section, ParkedDomainsFoundViewController.Item>

@MainActor
final class ParkedDomainsFoundViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [] }
    var presenter: ParkedDomainsFoundViewPresenterProtocol!
    private var dataSource: ParkedDomainsFoundDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - ParkedDomainsFoundViewProtocol
extension ParkedDomainsFoundViewController: ParkedDomainsFoundViewProtocol {
    func applySnapshot(_ snapshot: ParkedDomainsFoundSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension ParkedDomainsFoundViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}

// MARK: - Private functions
private extension ParkedDomainsFoundViewController {

}

// MARK: - Setup functions
private extension ParkedDomainsFoundViewController {
    func setup() {
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ParkedDomainsFoundDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            
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
            
            layoutSection = .flexibleListItemSection()
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 1,
                                                                  leading: spacing + 1,
                                                                  bottom: 1,
                                                                  trailing: spacing + 1)
            let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
            layoutSection.decorationItems = [background]
            
            
            return layoutSection
            
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ParkedDomainsFoundViewController {
    enum Section: Int, Hashable {
        case main
    }
    
    enum Item: Hashable {
        
    }
    
}
