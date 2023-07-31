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
    func setNavigationWith(selectedWallet: WalletDisplayInfo, wallets: [ChatsListNavigationView.WalletTitleInfo], isLoading: Bool)
    func stopSearching()
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
    private let operationQueue = OperationQueue()

    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var isObservingKeyboard: Bool { true }
    override var scrollableContentYOffset: CGFloat? { searchBarConfiguration == nil ? 24 : 48 }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? {
        switch state {
        case .chatsList: return cSearchBarConfiguration
        case .createProfile, .loading, .requestsList: return nil
        }
    }
    private var searchBar: UDSearchBar = UDSearchBar()
    private lazy var cSearchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration = {
        .init(searchBarPlacement: .inline) { [weak self] in
            self?.searchBar ?? UDSearchBar()
        }
    }()
    private var searchMode: ChatsList.SearchMode = .default

    override func viewDidLoad() {
        super.viewDidLoad()
        
        operationQueue.maxConcurrentOperationCount = 1
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
    }
     
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        presenter.viewDidAppear()
        cNavigationBar?.navBarContentView.setTitleView(hidden: false, animated: false)
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        collectionView.contentInset.bottom = keyboardHeight + Constants.scrollableContentBottomOffset
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        collectionView.contentInset.bottom = Constants.scrollableContentBottomOffset
    }
    
    override func shouldPopOnBackButton() -> Bool {
        presenter.viewWillDismiss()
        return true
    }
}

// MARK: - ChatsListViewProtocol
extension ChatsListViewController: ChatsListViewProtocol {
    func applySnapshot(_ snapshot: ChatsListSnapshot, animated: Bool) {
        let operation = CollectionReloadDiffableDataOperation(dataSource: dataSource,
                                                              snapshot: snapshot,
                                                              animated: animated)
        operationQueue.addOperation(operation)
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
    
    func setNavigationWith(selectedWallet: WalletDisplayInfo,
                           wallets: [ChatsListNavigationView.WalletTitleInfo],
                           isLoading: Bool) {
        navView?.setWithConfiguration(.init(selectedWallet: selectedWallet,
                                            wallets: wallets,
                                            isLoading: isLoading))
    }
    
    func stopSearching() {
        hideKeyboard()
        if searchBar.isEditing {
            searchBar.text = ""
            searchBar.forceLayout()
            udSearchBarTextDidEndEditing(searchBar)
        }
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

// MARK: - UISearchBarDelegate
extension ChatsListViewController: UDSearchBarDelegate {
    func udSearchBarTextDidBeginEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStartSearching)
        setupCollectionInset(isSearchActive: true)
        presenter.didStartSearch(with: searchMode)
    }
    
    func udSearchBar(_ udSearchBar: UDSearchBar, textDidChange searchText: String) {
        logAnalytic(event: .didSearch, parameters: [.domainName : searchText])
        presenter.didSearchWith(key: searchText)
    }
    
    func udSearchBarClearButtonClicked(_ udSearchBar: UDSearchBar) {
        udSearchBarTextDidEndEditing(udSearchBar)
    }
    
    func udSearchBarCancelButtonClicked(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStopSearching)
        UDVibration.buttonTap.vibrate()
        setSearchBarActive(false)
        presenter.didStopSearch()
    }
    
    func udSearchBarTextDidEndEditing(_ udSearchBar: UDSearchBar) {
        if !udSearchBar.isEditing {
            searchBar.text = ""
            logAnalytic(event: .didStopSearching)
            setSearchBarActive(false)
            presenter.didStopSearch()
        }
    }
}

// MARK: - Private functions
private extension ChatsListViewController {
    @IBAction func actionButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .createMessagingProfile)
        presenter.actionButtonPressed()
    }
    
    @objc func newMessageButtonPressed() {
        logButtonPressedAnalyticEvents(button: .newMessage)
        UDVibration.buttonTap.vibrate()
        searchMode = .chatsOnly
        searchBar.becomeFirstResponder()
    }
    
    func checkIfCollectionScrollingEnabled() {
        switch state {
        case .chatsList, .loading, .requestsList:
            collectionView.isScrollEnabled = true
        case .createProfile:
            let collectionViewVisibleHeight = collectionView.bounds.height - collectionView.contentInset.top - actionButtonContainerView.bounds.height
            collectionView.isScrollEnabled = collectionView.contentSize.height > collectionViewVisibleHeight
        }
    }
    
    func setSearchBarActive(_ isActive: Bool) {
        setupCollectionInset(isSearchActive: isActive)
        cNavigationBar?.setSearchActive(isActive, animated: true)
        if !isActive {
            searchMode = .default
        }
    }
}

// MARK: - Setup functions
private extension ChatsListViewController {
    func setup() {
        setupNavigation()
        setupCollectionView()
        setupActionButton()
        searchBar.delegate = self
    }
    
    func setupNavigation() {
        func addNavViewIfNil() {
            if navView == nil {
                navView = ChatsListNavigationView()
                navView.walletSelectedCallback = { [weak self] wallet in
                    self?.presenter.didSelectWallet(wallet)
                }
                navView.pressedCallback = { [weak self] in
                    self?.logButtonPressedAnalyticEvents(button: .messagingProfileSelection)
                }
                navigationItem.titleView = navView
            }
        }
        
        switch state {
        case .chatsList:
            addNavViewIfNil()
            navView?.isHidden = false
            let newMessageButton = UIBarButtonItem(image: .newMessageIcon,
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(newMessageButtonPressed))
            newMessageButton.tintColor = .foregroundDefault
            navigationItem.rightBarButtonItem = newMessageButton
        case .createProfile:
            addNavViewIfNil()
            navView?.isHidden = false
            navigationItem.rightBarButtonItem = nil
        case .loading:
            addNavViewIfNil()
            navView?.isHidden = true
            navigationItem.rightBarButtonItem = nil
        case .requestsList(let dataType):
            navigationItem.titleView = nil
            switch dataType {
            case .chats:
                title = String.Constants.chatRequests.localized()
            case .channels:
                title = String.Constants.spam.localized()
            }
            cNavigationBar?.navBarContentView.setTitle(hidden: false, animated: true)
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
        case .chatsList, .loading, .requestsList:
            actionButtonContainerView.isHidden = true
        case .createProfile:
            actionButtonContainerView.isHidden = false
        }
    }
    
    func setupCollectionInset(isSearchActive: Bool = false) {
        switch state {
        case .chatsList, .loading:
            collectionView.contentInset.top = isSearchActive ? 58 : 110
        case .createProfile, .requestsList:
            collectionView.contentInset.top = 68
        }
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(ChatsListSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ChatsListSectionHeaderView.reuseIdentifier)
        setupCollectionInset()
        
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatsListDataSource.init(collectionView: collectionView, cellProvider: {  [weak self] collectionView, indexPath, item in
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
                cell.setWith(configuration: configuration,
                             actionButtonCallback: {
                    self?.logButtonPressedAnalyticEvents(button: .emptyMessagingAction,
                                                         parameters: [.value: configuration.dataType.rawValue])
                    switch configuration.dataType {
                    case .channels:
                        self?.searchMode = .channelsOnly
                    case .chats:
                        self?.searchMode = .chatsOnly
                    }
                    self?.setSearchBarActive(true)
                })
                
                return cell
            case .userInfo(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .emptySearch:
                let cell = collectionView.dequeueCellOfType(ChatListEmptyCell.self, forIndexPath: indexPath)
                cell.setSearchStateUI()
                
                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                       withReuseIdentifier: ChatsListSectionHeaderView.reuseIdentifier,
                                                                       for: indexPath) as! ChatsListSectionHeaderView
            
            if let section = self?.section(at: indexPath),
               let header = section.header {
                view.setHeader(header)
            }
            
            return view
        }
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
            case .listItems(let title):
                layoutSection = .flexibleListItemSection()
         
                let background = NSCollectionLayoutDecorationItem.background(elementKind: CollectionReusableRoundedBackground.reuseIdentifier)
                
                if title != nil {
                    let sectionHeaderHeight = ChatsListSectionHeaderView.Height
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .absolute(sectionHeaderHeight))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                             elementKind: UICollectionView.elementKindSectionHeader,
                                                                             alignment: .top)
                    layoutSection.boundarySupplementaryItems = [header]
                    background.contentInsets.top = sectionHeaderHeight
                }
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
            case .emptyState, .none:
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
        case domainsSelection, listItems(title: String?), dataTypeSelection, createProfile, emptyState
        
        var header: String? {
            switch self {
            case .listItems(let title):
                return title
            default:
                return nil
            }
        }
    }
    
    enum Item: Hashable {
        case chat(configuration: ChatUIConfiguration)
        case domainSelection(configuration: DomainSelectionUIConfiguration)
        case dataTypeSelection(configuration: DataTypeSelectionUIConfiguration)
        case chatRequests(configuration: ChatRequestsUIConfiguration)
        case channel(configuration: ChannelUIConfiguration)
        case createProfile
        case emptyState(configuration: EmptyStateUIConfiguration)
        case userInfo(configuration: UserInfoUIConfiguration)
        case emptySearch
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
    
    enum DataType: String, Hashable {
        case chats, channels
        
        var title: String {
            switch self {
            case .chats:
                return String.Constants.chats.localized()
            case .channels:
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
    
    struct UserInfoUIConfiguration: Hashable {
        let userInfo: MessagingChatUserDisplayInfo
    }
    
    enum State {
        case createProfile
        case chatsList
        case loading
        case requestsList(DataType)
    }
}
