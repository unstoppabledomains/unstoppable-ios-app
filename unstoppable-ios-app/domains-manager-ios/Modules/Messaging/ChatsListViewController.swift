//
//  ChatsListViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2023.
//

import UIKit

@MainActor
protocol ChatsListViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ChatsListSnapshot, animated: Bool)
}

typealias ChatsListDataSource = UICollectionViewDiffableDataSource<ChatsListViewController.Section, ChatsListViewController.Item>
typealias ChatsListSnapshot = NSDiffableDataSourceSnapshot<ChatsListViewController.Section, ChatsListViewController.Item>

@MainActor
final class ChatsListViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChatListCell.self] }
    var presenter: ChatsListViewPresenterProtocol!
    private var dataSource: ChatsListDataSource!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
}

// MARK: - ChatsListViewProtocol
extension ChatsListViewController: ChatsListViewProtocol {
    func applySnapshot(_ snapshot: ChatsListSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}

// MARK: - UICollectionViewDelegate
extension ChatsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
}

// MARK: - Private functions
private extension ChatsListViewController {

}

// MARK: - Setup functions
private extension ChatsListViewController {
    func setup() {
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatsListDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .channel(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
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
extension ChatsListViewController {
    enum Section: Int, Hashable {
        case main
    }
    
    enum Item: Hashable {
        case channel(configuration: ChatChannelUIConfiguration)
    }
    
    struct ChatChannelUIConfiguration: Hashable {
        let channelType: ChatChannelType
    }
}
