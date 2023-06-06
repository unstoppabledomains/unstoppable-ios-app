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

typealias ChatsListDataType = ChatsListViewController.DataType
typealias ChatsListDataSource = UICollectionViewDiffableDataSource<ChatsListViewController.Section, ChatsListViewController.Item>
typealias ChatsListSnapshot = NSDiffableDataSourceSnapshot<ChatsListViewController.Section, ChatsListViewController.Item>

@MainActor
final class ChatsListViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChatListCell.self,
                                                        ChatListDomainSelectionCell.self,
                                                        ChatListDataTypeSelectionCell.self] }
    var presenter: ChatsListViewPresenterProtocol!
    private var dataSource: ChatsListDataSource!
    
    override var scrollableContentYOffset: CGFloat? { 48 }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? { cSearchBarConfiguration }
    private var searchBar: UDSearchBar = UDSearchBar()
    private lazy var cSearchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration = {
        .init(searchBarPlacement: .inline) { [weak self] in
            self?.searchBar ?? UDSearchBar()
        }
    }()
    
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - Private functions
private extension ChatsListViewController {

}

// MARK: - Setup functions
private extension ChatsListViewController {
    func setup() {
        setupCollectionView()
        title = String.Constants.chats.localized()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 110

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatsListDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .channel(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .domainSelection(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListDomainSelectionCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .dataTypeSelection(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListDataTypeSelectionCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            }
        })
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = 18
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection
            let section = self?.section(at: IndexPath(item: 0, section: sectionIndex))

            switch section {
            case .channels, .none:
                layoutSection = .flexibleListItemSection()
         
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                layoutSection.decorationItems = [background]
            case .dataTypeSelection:
                layoutSection = .flexibleListItemSection()
            case .domainsSelection:
                let leadingItem = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(40),
                                                       heightDimension: .fractionalHeight(1)))
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(40),
                                                       heightDimension: .absolute(36)),
                    subitems: [leadingItem])
                layoutSection = NSCollectionLayoutSection(group: containerGroup)
                layoutSection.interGroupSpacing = 8
                layoutSection.orthogonalScrollingBehavior = .continuous
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
    
    func section(at indexPath: IndexPath) -> Section? {
        self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
    }
    
}

// MARK: - Collection elements
extension ChatsListViewController {
    enum Section: Hashable {
        case domainsSelection, channels, dataTypeSelection
    }
    
    enum Item: Hashable {
        case channel(configuration: ChatChannelUIConfiguration)
        case domainSelection(configuration: DomainSelectionUIConfiguration)
        case dataTypeSelection(configuration: DataTypeSelectionUIConfiguration)
    }
    
    struct ChatChannelUIConfiguration: Hashable {
        let chat: MessagingChatDisplayInfo
    }
    
    struct DomainSelectionUIConfiguration: Hashable {
        let domain: DomainDisplayInfo
        let isSelected: Bool
        let unreadMessagesCount: Int
    }
    
    struct DataTypeSelectionUIConfiguration: Hashable {
        let dataTypesConfigurations: [DataTypeUIConfiguration]
        let selectedDataType: DataType
        var dataTypeChangedCallback: (DataType)->()
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.dataTypesConfigurations == rhs.dataTypesConfigurations &&
            lhs.selectedDataType == rhs.selectedDataType
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(dataTypesConfigurations)
            hasher.combine(selectedDataType)
        }
    }
    
    struct DataTypeUIConfiguration: Hashable {
        let dataType: DataType
        let badge: Int
    }
    
    enum DataType: Hashable {
        case chats, inbox
        
        var title: String {
            switch self {
            case .chats:
                return String.Constants.chats.localized()
            case .inbox:
                return String.Constants.appsInbox.localized()
            }
        }
    }
}
