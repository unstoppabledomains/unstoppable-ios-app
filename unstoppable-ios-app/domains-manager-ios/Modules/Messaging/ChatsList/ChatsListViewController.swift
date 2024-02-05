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
    func setNavigationWith(navigationState: ChatsListNavigationView.State,
                           isSelectable: Bool)
    func stopSearching()
    func setActivityIndicator(active: Bool)
}

typealias ChatsListDataType = ChatsListViewController.DataType
typealias ChatsListDataSource = UICollectionViewDiffableDataSource<ChatsListViewController.Section, ChatsListViewController.Item>
typealias ChatsListSnapshot = NSDiffableDataSourceSnapshot<ChatsListViewController.Section, ChatsListViewController.Item>

@MainActor
final class ChatsListViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var actionButtonContainerView: UIView!
    @IBOutlet private weak var actionButtonsStack: UIStackView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChatListCell.self,
                                                        ChatListDomainSelectionCell.self,
                                                        ChatListDataTypeSelectionCell.self,
                                                        ChatListRequestsCell.self,
                                                        ChatListCreateProfileCell.self,
                                                        ChatListEmptyCell.self,
                                                        CommunityListCell.self] }
    var presenter: ChatsListViewPresenterProtocol!
    var router: HomeTabRouter?
    private var dataSource: ChatsListDataSource!
    private var navView: ChatsListNavigationView!
    private var state: State = .loading
    private let operationQueue = OperationQueue()
    private let scrollableContentBottomOffset: CGFloat = 52

    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var isObservingKeyboard: Bool { true }
    override var scrollableContentYOffset: CGFloat? { searchBarConfiguration == nil ? 24 : 48 }
    override var searchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration? {
        switch state {
        case .chatsList: return cSearchBarConfiguration
        case .createProfile, .loading, .requestsList, .noWallet: return nil
        }
    }
    private var searchBar: UDSearchBar = UDSearchBar()
    private lazy var cSearchBarConfiguration: CNavigationBarContentView.SearchBarConfiguration = {
        .init(searchBarPlacement: .inline) { [weak self] in
            let searchBar = self?.searchBar ?? UDSearchBar()
            searchBar.setCorrectionType(.no)
            searchBar.setAutoCapitalizationType(.none)
            return searchBar
        }
    }()
    private var searchMode: ChatsList.SearchMode = .default
    private var mode: Mode = .default

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
        collectionView.contentInset.bottom = keyboardHeight + scrollableContentBottomOffset
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        collectionView.contentInset.bottom = scrollableContentBottomOffset
    }
    
    override func shouldPopOnBackButton() -> Bool {
        !searchBar.isEditing && mode == .default
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
            setAndAnimateCollectionViewHidden(true)
            activityIndicator.startAnimating()
        } else {
            setAndAnimateCollectionViewHidden(false)
            activityIndicator.stopAnimating()
        }
        
        setupCollectionTopInset()
        setupActionButton()
        setupNavigation()
        cNavigationController?.updateNavigationBar()
    }
 
    func setNavigationWith(navigationState: ChatsListNavigationView.State,
                           isSelectable: Bool) {
        navView?.setWithState(navigationState, isSelectable: isSelectable)
    }
    
    func stopSearching() {
        hideKeyboard()
        if searchBar.isEditing {
            searchBar.text = ""
            searchBar.forceLayout()
            udSearchBarTextDidEndEditing(searchBar)
        }
    }
    
    func setActivityIndicator(active: Bool) {
        view.isUserInteractionEnabled = !active
        if active {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ChatsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item, mode: mode)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
}

// MARK: - UISearchBarDelegate
extension ChatsListViewController: UDSearchBarDelegate {
    func udSearchBarTextDidBeginEditing(_ udSearchBar: UDSearchBar) {
        logAnalytic(event: .didStartSearching)
        setupCollectionTopInset(isSearchActive: true)
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
    @objc func actionButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .createMessagingProfile)
        presenter.actionButtonPressed()
    }
    
    @objc func bulkBlockButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .bulkBlockButtonPressed)
        presenter.actionButtonPressed()
        toggleCurrentMode()
    }
    
    @objc func newMessageButtonPressed() {
        logButtonPressedAnalyticEvents(button: .newMessage)
        UDVibration.buttonTap.vibrate()
        searchMode = .chatsOnly
        searchBar.becomeFirstResponder()
    }
    
    @objc func editButtonPressed() {
        UDVibration.buttonTap.vibrate()
        switch mode {
        case .default:
            logButtonPressedAnalyticEvents(button: .edit)
            presenter.editingModeActionButtonPressed(.edit)
        case .editing:
            logButtonPressedAnalyticEvents(button: .cancel)
            presenter.editingModeActionButtonPressed(.cancel)
        }
        
        toggleCurrentMode()
    }
    
    func toggleCurrentMode() {
        switch mode {
        case .default:
            mode = .editing
            collectionView.contentInset.bottom = actionButtonContainerView.bounds.height
            cNavigationBar?.setBackButton(hidden: true)
        case .editing:
            mode = .default
            collectionView.contentInset.bottom = scrollableContentBottomOffset
            cNavigationBar?.setBackButton(hidden: false)
        }
        
        setupActionButton()
        setupNavigation()
        cNavigationController?.updateNavigationBar()
        collectionView.reloadData()
        switch mode {
        case .default:
            cNavigationBar?.setBackButton(hidden: false)
        case .editing:
            cNavigationBar?.setBackButton(hidden: true)
        }
    }
    
    @objc func selectAllButtonPressed() {
        UDVibration.buttonTap.vibrate()
        presenter.editingModeActionButtonPressed(.selectAll)
    }
    
    func checkIfCollectionScrollingEnabled() {
        switch state {
        case .chatsList, .loading, .requestsList, .noWallet:
            collectionView.isScrollEnabled = true
        case .createProfile:
            let collectionViewVisibleHeight = collectionView.bounds.height - collectionView.contentInset.top - actionButtonContainerView.bounds.height
            collectionView.isScrollEnabled = collectionView.contentSize.height > collectionViewVisibleHeight
        }
    }
    
    func setSearchBarActive(_ isActive: Bool) {
        setupCollectionTopInset(isSearchActive: isActive)
        cNavigationBar?.setSearchActive(isActive, animated: true)
        if !isActive {
            searchMode = .default
            collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.contentInset.top), animated: true)
        }
    }
    
    func setAndAnimateCollectionViewHidden(_ hidden: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.collectionView.alpha = hidden ? 0 : 1
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
                navView.pressedCallback = { [weak self] in
                    self?.router?.isSelectProfilePresented = true
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
        case .createProfile, .noWallet:
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
                let buttonTitle: String
                switch mode {
                case .default:
                    buttonTitle = String.Constants.editButtonTitle.localized()
                    navigationItem.leftBarButtonItem = nil
                case .editing:
                    buttonTitle = String.Constants.cancel.localized()
                    
                    let selectAllButton = UIBarButtonItem(title: String.Constants.selectAll.localized(),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(selectAllButtonPressed))
                    selectAllButton.tintColor = .foregroundDefault
                    navigationItem.leftBarButtonItem = selectAllButton
                }
                let editButton = UIBarButtonItem(title: buttonTitle,
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(editButtonPressed))
                editButton.tintColor = .foregroundDefault
                navigationItem.rightBarButtonItem = editButton
            case .channels:
                title = String.Constants.spam.localized()
            case .communities:
                Debugger.printFailure("Requests section are not exist for communities", critical: true)
            }
            cNavigationBar?.navBarContentView.setTitle(hidden: false, animated: true)
        }
    }
    
    func setupActionButton() {
        switch state {
        case .chatsList, .loading, .noWallet:
            actionButtonContainerView.isHidden = true
        case .requestsList:
            switch mode {
            case .default:
                actionButtonContainerView.isHidden = true
            case .editing:
                actionButtonContainerView.isHidden = false
                let blockButton = PrimaryDangerButton()
                blockButton.translatesAutoresizingMaskIntoConstraints = false
                blockButton.addTarget(self, action: #selector(bulkBlockButtonPressed), for: .touchUpInside)
                blockButton.setTitle(String.Constants.block.localized(),
                                      image: .systemMultiplyCircle)
                actionButtonsStack.removeArrangedSubviews()
                actionButtonsStack.addArrangedSubview(blockButton)
            }
        case .createProfile:
            actionButtonContainerView.isHidden = false
            let actionButton = MainButton()
            actionButton.translatesAutoresizingMaskIntoConstraints = false
            actionButton.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
            var icon: UIImage?
            if User.instance.getSettings().touchIdActivated {
                icon = appContext.authentificationService.biometricIcon
            }
            actionButton.setTitle(String.Constants.enable.localized(),
                                  image: icon)
            actionButtonsStack.removeArrangedSubviews()
            actionButtonsStack.addArrangedSubview(actionButton)
        }
    }
    
    func setupCollectionTopInset(isSearchActive: Bool = false) {
        switch state {
        case .chatsList, .loading:
            collectionView.contentInset.top = isSearchActive ? 58 : 110
        case .createProfile, .requestsList, .noWallet:
            collectionView.contentInset.top = 68
        }
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.register(ChatsListSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ChatsListSectionHeaderView.reuseIdentifier)
        setupCollectionTopInset()
        collectionView.contentInset.bottom = scrollableContentBottomOffset

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatsListDataSource.init(collectionView: collectionView, cellProvider: {  [weak self] collectionView, indexPath, item in
            switch item {
            case .chat(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatListCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration, isEditing: self?.mode == .editing)
                
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
                    switch configuration {
                    case .emptyData(let dataType, _):
                        self?.logButtonPressedAnalyticEvents(button: .emptyMessagingAction,
                                                             parameters: [.value: dataType.rawValue])
                        switch dataType {
                        case .channels:
                            self?.searchMode = .channelsOnly
                        case .chats:
                            self?.searchMode = .chatsOnly
                        case .communities:
                            self?.openLink(.communitiesInfo)
                            return
                        }
                        self?.setSearchBarActive(true)
                    case .noCommunitiesProfile:
                        self?.logButtonPressedAnalyticEvents(button: .createCommunityProfile)
                        self?.presenter.createCommunitiesProfileButtonPressed()
                    case .noWalletAdded:
                        self?.logButtonPressedAnalyticEvents(button: .addWallet)
                        self?.router?.runAddWalletFlow()
                    }
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
            case .community(let configuration):
                let cell = collectionView.dequeueCellOfType(CommunityListCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
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
    
    enum Item: Hashable, Sendable {
        case chat(configuration: ChatUIConfiguration)
        case domainSelection(configuration: DomainSelectionUIConfiguration)
        case dataTypeSelection(configuration: DataTypeSelectionUIConfiguration)
        case chatRequests(configuration: ChatRequestsUIConfiguration)
        case channel(configuration: ChannelUIConfiguration)
        case createProfile
        case emptyState(configuration: EmptyStateUIConfiguration)
        case userInfo(configuration: UserInfoUIConfiguration)
        case emptySearch
        case community(configuration: CommunityUIConfiguration)
    }
    
    struct ChatUIConfiguration: Hashable {
        let chat: MessagingChatDisplayInfo
        var isSelected: Bool = false 
        var isSpam: Bool = false 
    }
    
    struct CommunityUIConfiguration: Hashable {
        let community: MessagingChatDisplayInfo
        let communityDetails: MessagingCommunitiesChatDetails
        let joinButtonPressedCallback: MainActorAsyncCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.communityDetails == rhs.communityDetails
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(communityDetails)
        }
    }
    
    struct DomainSelectionUIConfiguration: Hashable {
        let domain: DomainDisplayInfo
        let isSelected: Bool
        let unreadMessagesCount: Int
    }
    
    struct DataTypeSelectionUIConfiguration: Hashable, Sendable {
        let dataTypesConfigurations: [DataTypeUIConfiguration]
        let selectedDataType: DataType
        var dataTypeChangedCallback: @Sendable @MainActor (DataType)->()
        
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
        case chats, communities, channels
        
        var title: String {
            switch self {
            case .chats:
                return String.Constants.chats.localized()
            case .communities:
                return String.Constants.communities.localized()
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
    
    enum EmptyStateUIConfiguration: Hashable {
        case emptyData(dataType: DataType, isRequestsList: Bool)
        case noCommunitiesProfile
        case noWalletAdded
    }
    
    struct UserInfoUIConfiguration: Hashable {
        let userInfo: MessagingChatUserDisplayInfo
    }
    
    enum State {
        case noWallet
        case createProfile
        case chatsList
        case loading
        case requestsList(DataType)
    }
    
    enum Mode {
        case `default`
        case editing
    }
}


import SwiftUI
struct ChatsListViewControllerWrapper: UIViewControllerRepresentable {
    
    @StateObject var navTracker: NavigationTracker
    
    init(tabState: HomeTabRouter) {
        self._navTracker = StateObject(wrappedValue: NavigationTracker(tabState: tabState))
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UDRouter().buildChatsListModule(presentOptions: .default)
        let nav = CNavigationController(rootViewController: vc)
        vc.router = navTracker.tabRouter
        nav.delegate = navTracker
        navTracker.tabRouter.chatsListCoordinator = vc.presenter as? ChatsListCoordinator
        vc.viewDidLoad()
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
    final class NavigationTracker: ObservableObject, CNavigationControllerDelegate {
        nonisolated
        init(tabState: HomeTabRouter) {
            self.tabRouter = tabState
        }
        
        let tabRouter: HomeTabRouter
        
        func navigationController(_ navigationController: CNavigationController, willShow viewController: UIViewController, animated: Bool) {
            if viewController != navigationController.rootViewController {
                withAnimation {
                    self.tabRouter.isTabBarVisible = false
                }
            }
        }
        
        func navigationController(_ navigationController: CNavigationController, didShow viewController: UIViewController, animated: Bool) {
            withAnimation {
                self.tabRouter.isTabBarVisible = viewController == navigationController.rootViewController
            }
        }
        
    }
}
