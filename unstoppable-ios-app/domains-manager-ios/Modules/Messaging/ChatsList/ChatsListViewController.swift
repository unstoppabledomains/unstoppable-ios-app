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
    func setState(_ state: ChatsListViewController.State)
    func setNavigationWith(selectedWallet: WalletDisplayInfo, wallets: [WalletDisplayInfo])
}

typealias ChatsListDataType = ChatsListViewController.DataType
typealias ChatsListDataSource = UICollectionViewDiffableDataSource<ChatsListViewController.Section, ChatsListViewController.Item>
typealias ChatsListSnapshot = NSDiffableDataSourceSnapshot<ChatsListViewController.Section, ChatsListViewController.Item>

@MainActor
final class ChatsListViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var actionButton: MainButton!
    @IBOutlet private weak var actionButtonContainerView: UIView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChatListCell.self,
                                                        ChatListDomainSelectionCell.self,
                                                        ChatListDataTypeSelectionCell.self,
                                                        ChatListRequestsCell.self,
                                                        ChatListCreateProfileCell.self,
                                                        ChatListEmptyCell.self] }
    var presenter: ChatsListViewPresenterProtocol!
    private var dataSource: ChatsListDataSource!
    private var navView: ChatsListNavigationView!
    private var state: State = .loading
    
    override var scrollableContentYOffset: CGFloat? { 48 }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? {
        switch state {
        case .chatsList: return cSearchBarConfiguration
        case .createProfile, .loading: return nil
        }
    }
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
        dataSource.apply(snapshot, animatingDifferences: animated, completion: { [weak self] in
            self?.checkIfCollectionScrollingEnabled()
        })
    }
    
    func setState(_ state: State) {
        self.state = state
        
        if case .loading = state {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        setupCollectionInset()
        setupActionButton()
        setupNavigation()
        cNavigationController?.updateNavigationBar()
    }
    
    func setNavigationWith(selectedWallet: WalletDisplayInfo, wallets: [WalletDisplayInfo]) {
        navView?.setWithConfiguration(.init(selectedWallet: selectedWallet,
                                            wallets: wallets))
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
    @IBAction func actionButtonPressed(_ sender: Any) {
        presenter.actionButtonPressed()
    }
    
    @objc func newMessageButtonPressed() {
        UDVibration.buttonTap.vibrate()
    }
    
    func checkIfCollectionScrollingEnabled() {
        switch state {
        case .chatsList, .loading:
            collectionView.isScrollEnabled = true
        case .createProfile:
            let collectionViewVisibleHeight = collectionView.bounds.height - collectionView.contentInset.top - actionButtonContainerView.bounds.height
            collectionView.isScrollEnabled = collectionView.contentSize.height > collectionViewVisibleHeight
        }
    }
}

// MARK: - Setup functions
private extension ChatsListViewController {
    func setup() {
        setupNavigation()
        setupCollectionView()
        setupActionButton()
    }
    
    func setupNavigation() {
        if navView == nil {
            navView = ChatsListNavigationView()
            navView.walletSelectedCallback = { [weak self] wallet in
                self?.presenter.didSelectWallet(wallet)
            }
            navigationItem.titleView = navView
        }
        
        switch state {
        case .chatsList:
            navView?.isHidden = false
            let newMessageButton = UIBarButtonItem(image: .newMessageIcon,
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(newMessageButtonPressed))
            newMessageButton.tintColor = .foregroundDefault
            navigationItem.rightBarButtonItem = newMessageButton
        case .createProfile:
            navView?.isHidden = false
            navigationItem.rightBarButtonItem = nil
        case .loading:
            navView?.isHidden = true
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func setupActionButton() {
        var icon: UIImage?
        if User.instance.getSettings().touchIdActivated {
            icon = appContext.authentificationService.biometricType == .faceID ? .faceIdIcon : .touchIdIcon
        }
        actionButton.setTitle(String.Constants.enable.localized(),
                              image: icon)
        
        switch state {
        case .chatsList, .loading:
            actionButtonContainerView.isHidden = true
        case .createProfile:
            actionButtonContainerView.isHidden = false
        }
    }
    
    func setupCollectionInset() {
        switch state {
        case .chatsList, .loading:
            collectionView.contentInset.top = 110
        case .createProfile:
            collectionView.contentInset.top = 68
        }
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        setupCollectionInset()

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatsListDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .chat(let configuration):
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
            case .chatRequests(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListRequestsCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .channel(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .createProfile:
                let cell = collectionView.dequeueCellOfType(ChatListCreateProfileCell.self, forIndexPath: indexPath)

                return cell
            case .emptyState(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListEmptyCell.self, forIndexPath: indexPath)
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
            case .dataTypeSelection, .createProfile:
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
            case .emptyState:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                                     heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .zero
                let containerGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                       heightDimension: .fractionalHeight(0.6)),
                    subitems: [item])
                layoutSection = NSCollectionLayoutSection(group: containerGroup)
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
        case domainsSelection, channels, dataTypeSelection, createProfile, emptyState
    }
    
    enum Item: Hashable {
        case chat(configuration: ChatUIConfiguration)
        case domainSelection(configuration: DomainSelectionUIConfiguration)
        case dataTypeSelection(configuration: DataTypeSelectionUIConfiguration)
        case chatRequests(configuration: ChatRequestsUIConfiguration)
        case channel(configuration: ChannelUIConfiguration)
        case createProfile
        case emptyState(configuration: EmptyStateUIConfiguration)
    }
    
    struct ChatUIConfiguration: Hashable {
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
    
    struct ChatRequestsUIConfiguration: Hashable {
        let dataType: DataType
        let numberOfRequests: Int
    }
    
    
    struct ChannelUIConfiguration: Hashable {
        let channel: MessagingNewsChannel
    }
    
    struct EmptyStateUIConfiguration: Hashable {
        let dataType: DataType
    }
    
    enum State {
        case createProfile
        case chatsList
        case loading
    }
}
