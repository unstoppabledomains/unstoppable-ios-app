//
//  ChatViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

@MainActor
protocol ChatViewProtocol: BaseDiffableCollectionViewControllerProtocol where Section == ChatViewController.Section, Item == ChatViewController.Item {
    func startTyping()
    func setInputText(_ text: String)
    func setPlaceholder(_ placeholder: String)
    func setTitleOfType(_ titleType: ChatTitleView.TitleType)
    func scrollToTheBottom(animated: Bool)
    func scrollToItem(_ item: ChatViewController.Item, animated: Bool)
    func setLoading(active: Bool)
    func setUIState(_ state: ChatViewController.State)
    func setupRightBarButton(with configuration: ChatViewController.NavButtonConfiguration)
    func setEmptyState(_ state: ChatEmptyView.State?)
}

typealias ChatDataSource = UICollectionViewDiffableDataSource<ChatViewController.Section, ChatViewController.Item>
typealias ChatSnapshot = NSDiffableDataSourceSnapshot<ChatViewController.Section, ChatViewController.Item>

@MainActor
final class ChatViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var chatInputView: ChatInputView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var approveContentView: UIView!
    @IBOutlet private weak var acceptButton: MainButton!
    @IBOutlet private weak var secondaryButton: UDButton!
    @IBOutlet private weak var moveToTopButton: FABButton!
    @IBOutlet private weak var chatEmptyView: ChatEmptyView!
    
    private var titleView: ChatTitleView!

    override var scrollableContentYOffset: CGFloat? { 13 }
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChatTextCell.self,
                                                        ChatImageCell.self,
                                                        ChatUnsupportedMessageCell.self,
                                                        ChannelFeedCell.self,
                                                        ChatLoadingCell.self,
                                                        ChatRemoteContentCell.self] }
    var presenter: ChatViewPresenterProtocol!
    let operationQueue = OperationQueue()
    private(set) var dataSource: DataSource!
    private var scrollingInfo: ScrollingInfo?
    private var moveToTopButtonVisibilityWorkItem: DispatchWorkItem?
    private var isMoveToTopButtonHidden = false
    private var state: State?
    override var isObservingKeyboard: Bool { true }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        operationQueue.maxConcurrentOperationCount = 1
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cNavigationBar?.navBarContentView.setTitleView(hidden: false, animated: true)
        presenter.viewWillAppear()
        DispatchQueue.main.async {
            self.calculateCollectionBottomInset()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideKeyboard()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        calculateCollectionBottomInset()
        calculateCollectionViewTopInset()
        scrollToTheBottom(animated: true)
    }
    
    override func keyboardWillHideAction(duration: Double, curve: Int) {
        calculateCollectionBottomInset()
        calculateCollectionViewTopInset()
    }
    
    override func keyboardDidAdjustFrame(keyboardHeight: CGFloat) {
        calculateCollectionBottomInset(shouldAdjustContentOffset: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupMoveToTopButtonFrame()
        setupEmptyViewFrame()
    }
}

// MARK: - ChatViewProtocol
extension ChatViewController: ChatViewProtocol {
    func applySnapshot(_ snapshot: Snapshot, animated: Bool, completion: EmptyCallback?) {
        scrollingInfo = ScrollingInfo(collectionView: collectionView)
        let operation = CollectionReloadDiffableDataOperation(dataSource: dataSource,
                                                              snapshot: snapshot,
                                                              animated: animated) { [weak self] in
            self?.scrollingInfo = nil
            self?.calculateCollectionViewTopInset()
            completion?()
        }
        operationQueue.addOperation(operation)
    }
    
    func startTyping() {
        chatInputView.startEditing()
    }
    
    func setInputText(_ text: String) {
        chatInputView.setText(text)
    }
    
    func setPlaceholder(_ placeholder: String) {
        chatInputView.setPlaceholder(placeholder)
    }
    
    func setTitleOfType(_ titleType: ChatTitleView.TitleType) {
        titleView.setTitleOfType(titleType)
    }
    
    func scrollToTheBottom(animated: Bool) {
        guard let indexPath = getLastItemIndexPath() else { return }
        Debugger.printInfo(topic: .Messaging, "Will scroll to the bottom at \(indexPath)")
        
        scrollTo(indexPath: indexPath, at: .bottom, animated: animated)
    }
    
    func scrollToItem(_ item: Item, animated: Bool) {
        guard let indexPath = dataSource.indexPath(for: item) else { return }

        scrollTo(indexPath: indexPath, at: .top, animated: animated)
    }
    
    func setLoading(active: Bool) {
        if active {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    func setUIState(_ state: ChatViewController.State) {
        self.state = state
        var animated = true
        if case .loading = state {
            animated = false
        }
        let animationDuration: TimeInterval = animated ? 0.25 : 0
        UIView.animate(withDuration: animationDuration) {
            self.updateUIForCurrentState()
        }
    }
    
    func setupRightBarButton(with configuration: NavButtonConfiguration) {
        let actions = configuration.actions
        
        if actions.isEmpty {
            navigationItem.rightBarButtonItem = nil
        } else {
            let barButton = UIButton()
            barButton.tintColor = .foregroundDefault
            barButton.setImage(.dotsCircleIcon, for: .normal)
            var children: [UIMenuElement] = []
            for action in actions {
                let actionType = action.type
                
                let uiAction = UIAction.createWith(title: actionType.title,
                                                   image: actionType.icon,
                                                   attributes: actionType.isDestructive ? [.destructive] : [],
                                                   handler: { _ in
                    UDVibration.buttonTap.vibrate()
                    action.callback()
                })
                if actionType.isDestructive {
                    let menu = UIMenu(title: "", options: .displayInline, children: [uiAction])
                    children.append(menu)
                } else {
                    children.append(uiAction)
                }
            }
            
            let menu = UIMenu(title: "", children: children)
            barButton.showsMenuAsPrimaryAction = true
            barButton.menu = menu
            barButton.addAction(UIAction(handler: { [weak self] _ in
                self?.logButtonPressedAnalyticEvents(button: .dots)
                UDVibration.buttonTap.vibrate()
            }), for: .menuActionTriggered)
            let barButtonItem = UIBarButtonItem(customView: barButton)
            navigationItem.rightBarButtonItem = barButtonItem
        }
        cNavigationController?.updateNavigationBar()
    }
    
    func setEmptyState(_ state: ChatEmptyView.State?) {
        if let state {
            chatEmptyView.setState(state)
            chatEmptyView.isHidden = false
        } else {
            chatEmptyView.isHidden = true
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ChatViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
        if let lastItemIndexPath = getLastItemIndexPath(),
           let cell = collectionView.cellForItem(at: lastItemIndexPath) {
            let cellFrameInView = collectionView.convert(cell.frame, to: view)
            let isChatInputViewTopBorderVisible = cellFrameInView.maxY >= chatInputView.frame.minY
            chatInputView.setTopBorderHidden(!isChatInputViewTopBorderVisible,
                                             animated: true)
        }
        
        if scrollView.contentSize.height > collectionView.bounds.height, // Check empty state
           scrollDistanceToEnd < -100 {
            setMoveToTopButton(hidden: false, animated: true)
        } else {
            setMoveToTopButton(hidden: true, animated: true)
        }
    }
    
    var scrollDistanceToEnd: CGFloat {
        collectionView.contentOffset.y - (collectionView.contentSize.height - collectionView.bounds.height + collectionView.contentInset.bottom)
    }
    
    var isReachedEnd: Bool {
        scrollDistanceToEnd >= 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.willDisplayItem(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: ChatSectionHeaderView.Height)
    }
 
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let scrollingInfo,
           isContentHeightBiggerThanVisibleFrame {
            let newContentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
            let delta = newContentHeight - scrollingInfo.prevContentHeight
            let adjustedOffset = CGPoint(x: proposedContentOffset.x, y: scrollingInfo.contentOffsetBeforeUpdate.y + delta)
            self.collectionView.contentOffset = adjustedOffset
            return adjustedOffset
        }
        return proposedContentOffset
    }
}

// MARK: - ChatInputViewDelegate
extension ChatViewController: ChatInputViewDelegate {
    func chatInputView(_ chatInputView: ChatInputView, didTypeText text: String) {
        presenter.didTypeText(text)
    }
    
    func chatInputView(_ chatInputView: ChatInputView, didSentText text: String) {
        logButtonPressedAnalyticEvents(button: .messageInputSend)
        presenter.didPressSendText(text)
    }
    
    func chatInputViewDidAdjustContentHeight(_ chatInputView: ChatInputView) {
        setupMoveToTopButtonFrame()
        setupEmptyViewFrame()
    }
    
    func chatInputViewAdditionalActionsButtonPressed(_ chatInputView: ChatInputView) {
        logButtonPressedAnalyticEvents(button: .messageInputPlus)
    }
    
    func chatInputViewAdditionalActionSelected(_ chatInputView: ChatInputView, action: ChatInputView.AdditionalAction) {
        logButtonPressedAnalyticEvents(button: .messageInputPlusAction, parameters: [.value: action.rawValue])
        switch action {
        case .choosePhoto:
            presenter.choosePhotoButtonPressed()
        case .takePhoto:
            presenter.takePhotoButtonPressed()
        }
    }
}

// MARK: - Actions
private extension ChatViewController {
    @IBAction func approveButtonPressed() {
        presenter.approveButtonPressed()
    }
    
    @IBAction func secondaryButtonPressed() {
        presenter.secondaryButtonPressed()
    }
    
    @IBAction func moveToTopButtonPressed(_ sender: Any) {
        logButtonPressedAnalyticEvents(button: .moveToTop)
        scrollToTheBottom(animated: true)
    }
}

// MARK: - Private functions
private extension ChatViewController {
    func updateUIForCurrentState() {
        secondaryButton.isUserInteractionEnabled = true
        secondaryButton.isHidden = true
        acceptButton.isHidden = true
        chatInputView.isHidden = true
        collectionView.alpha = 1
        approveContentView.isHidden = true
        
        switch state {
        case .loading:
            collectionView.alpha = 0
        case .chat:
            chatInputView.isHidden = false
        case .viewChannel:
            UIView.performWithoutAnimation {
                calculateCollectionBottomInset()
            }
        case .joinChannel:
            approveContentView.isHidden = false
            acceptButton.isHidden = false
            acceptButton.setTitle(String.Constants.join.localized(), image: nil)
        case .otherUserIsBlocked:
            approveContentView.isHidden = false
            secondaryButton.isHidden = false
            secondaryButton.setConfiguration(.mediumGhostPrimaryButtonConfiguration())
            secondaryButton.setTitle(String.Constants.unblock.localized(), image: nil)
        case .userIsBlocked:
            approveContentView.isHidden = false
            secondaryButton.isHidden = false
            var configuration = UDButtonConfiguration.mediumRaisedTertiaryButtonConfiguration
            configuration.backgroundIdleColor = .clear
            secondaryButton.setConfiguration(configuration)
            secondaryButton.isUserInteractionEnabled = false
            secondaryButton.setTitle(String.Constants.messagingYouAreBlocked.localized(), image: nil)
        case .cantContactUser(let ableToInvite):
            if ableToInvite {
                approveContentView.isHidden = false
                acceptButton.isHidden = false
                acceptButton.setTitle(String.Constants.messagingInvite.localized(), image: nil)
            }
        case .none:
            return
        }
    }
    
    func calculateCollectionHeightToContentHeightDiff() -> CGFloat {
        let contentHeight = collectionView.contentSize.height
        let viewHeight = collectionView.bounds.height - (cNavigationBar?.bounds.height ?? 0) - currentChatInputViewHeight
        let contentToBoundsDiff = viewHeight - contentHeight
        return contentToBoundsDiff
    }
    
    var currentKeyboardHeight: CGFloat { isKeyboardOpened ? keyboardFrame.height : 0 }
    var currentChatInputViewHeight: CGFloat { 
        switch state {
        case .viewChannel:
            return 16
        default:
            return chatInputView.bounds.height
        }
    }
    
    func calculateCollectionBottomInset(shouldAdjustContentOffset: Bool = false) {
        let keyboardHeight = currentKeyboardHeight
        let currentInset = collectionView.contentInset.bottom
        
        collectionView.contentInset.bottom = currentChatInputViewHeight + keyboardHeight + 12
        if shouldAdjustContentOffset {
            let insetDif = currentInset - collectionView.contentInset.bottom
            if isReachedEnd,
               insetDif > 0 { /// Content will be adjusted automatically
                return
            }
            self.collectionView.contentOffset.y -= insetDif
        }
    }
    
    func calculateCollectionViewTopInset() {
        let baseInset: CGFloat = 56
        let currentKeyboardHeight = self.currentKeyboardHeight
        let contentToBoundsDiff = calculateCollectionHeightToContentHeightDiff()
        if (contentToBoundsDiff - currentKeyboardHeight) > 0 {
            collectionView.contentInset.top = contentToBoundsDiff + baseInset - currentKeyboardHeight
        } else {
            collectionView.contentInset.top = baseInset
        }
    }
    
    func getLastItemIndexPath() -> IndexPath? {
        guard let snapshot = dataSource?.snapshot() else { return nil }
        let sections = snapshot.sectionIdentifiers
        
        guard let section = sections.last else { return nil }
        
        let itemsCount = snapshot.numberOfItems(inSection: section)
        guard itemsCount > 0 else { return nil }
        
        let indexPath = IndexPath(item: itemsCount - 1, section: sections.count - 1)
        return indexPath
    }
    
    func scrollTo(indexPath: IndexPath, at position: UICollectionView.ScrollPosition, animated: Bool) {
        self.collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
        UIView.performWithoutAnimation {
            let yOffset = CNavigationHelper.contentYOffset(of: self.collectionView)
            self.cNavigationBar?.setBlur(hidden: yOffset < self.scrollableContentYOffset!)
        }
    }
    
    func setMoveToTopButton(hidden: Bool, animated: Bool) {
        guard isMoveToTopButtonHidden != hidden else { return }
        
        isMoveToTopButtonHidden = hidden
        moveToTopButtonVisibilityWorkItem?.cancel()
        let moveToTopButtonVisibilityWorkItem = DispatchWorkItem(block: { [weak self] in
            UIView.animate(withDuration: animated ? 0.25 : 0.0) {
                self?.moveToTopButton.alpha = hidden ? 0 : 1
            }
        })
        self.moveToTopButtonVisibilityWorkItem = moveToTopButtonVisibilityWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.2 : 0.0), execute: moveToTopButtonVisibilityWorkItem)
    }
    
    func setupMoveToTopButtonFrame() {
        let moveToTopButtonSize: CGFloat = 48
        let edgeSpacing: CGFloat = 16
        moveToTopButton.frame = CGRect(origin: CGPoint(x: view.bounds.width - moveToTopButtonSize - edgeSpacing,
                                                       y: chatInputView.frame.minY - moveToTopButtonSize - edgeSpacing),
                                       size: .square(size: moveToTopButtonSize))
    }
    
    var isContentHeightBiggerThanVisibleFrame: Bool {
        let newContentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        if newContentHeight > view.bounds.height {
            return true
        }
        let visibleChatHeight = view.bounds.height - (view.bounds.height - chatInputView.frame.minY) - (cNavigationBar?.bounds.height ?? 0)
        return newContentHeight > visibleChatHeight
    }
    
    func setupEmptyViewFrame() {
        let y = cNavigationBar?.frame.height ?? 0
        let height = view.bounds.height - y - (view.bounds.height - chatInputView.frame.minY)
        chatEmptyView.frame = CGRect(x: 0,
                                     y: y,
                                     width: view.bounds.width,
                                     height: height)
    }
    
    func userDidTapImage(_ image: UIImage) {
        let imageDetailsVC = MessagingImageView.instantiate(mode: .view(saveCallback: { [weak self] in
            self?.saveImage(image)
        }), image: image)
        present(imageDetailsVC, animated: true)
    }
    
    func saveImage(_ image: UIImage) {
        appContext.permissionsService.askPermissionsFor(functionality: .photoLibrary(options: .addOnly),
                                                        in: presentedViewController,
                                                        shouldShowAlertIfNotGranted: true) { granted in
            if granted {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(Self.handleImageSavingWith(image:error:contextInfo:)), nil)
            }
        }
    }
    
    @objc func handleImageSavingWith(image: UIImage, error: Error?, contextInfo: UnsafeRawPointer) {
        Task { @MainActor in
            if error != nil {
                Vibration.error.vibrate()
            } else {
                Vibration.success.vibrate()
            }
        }
    }
}

// MARK: - Setup functions
private extension ChatViewController {
    func setup() {
        setupInputView()
        setupApproveRequestView()
        setupNavBar()
        setupMoveToTopButton()
        setupCollectionView()
        setupHideKeyboardTap()
        setEmptyState(nil)
    }
    
    func setupInputView() {
        chatInputView.frame.origin.x = 0
        chatInputView.frame.origin.y = self.view.bounds.height - ChatInputView.height
        chatInputView.setTopBorderHidden(true, animated: false)
        chatInputView.delegate = self
    }
    
    func setupApproveRequestView() {
        approveContentView.isHidden = true
        secondaryButton.isHidden = true
    }
    
    func setupNavBar() {
        titleView = ChatTitleView()
        navigationItem.titleView = titleView
    }
    
    func setupMoveToTopButton() {
        moveToTopButton.customImageEdgePadding = 0
        moveToTopButton.customTitleEdgePadding = 0
        moveToTopButton.setTitle(nil, image: .chevronDown)
        setMoveToTopButton(hidden: true, animated: false)
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        calculateCollectionViewTopInset()
        collectionView.showsVerticalScrollIndicator = true
        collectionView.register(ChatSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ChatSectionHeaderView.reuseIdentifier)

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatDataSource.init(collectionView: collectionView, cellProvider: { [weak self] collectionView, indexPath, item in
            switch item {
            case .textMessage(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatTextCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .imageBase64Message(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatImageCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                cell.imagePressedCallback = { image in
                    self?.userDidTapImage(image)
                }
                
                return cell
            case .imageDataMessage(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatImageCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                cell.imagePressedCallback = { image in
                    self?.userDidTapImage(image)
                }
                
                return cell
            case .unsupportedMessage(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatUnsupportedMessageCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .remoteContentMessage(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatRemoteContentCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .channelFeed(let configuration):
                let cell = collectionView.dequeueCellOfType(ChannelFeedCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
                return cell
            case .loading:
                let cell = collectionView.dequeueCellOfType(ChatLoadingCell.self, forIndexPath: indexPath)

                return cell
            }
        })
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, elementKind, indexPath in
            let section = self?.section(at: indexPath)

            switch section {
            case .messages(let title):
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind,
                                                                           withReuseIdentifier: ChatSectionHeaderView.reuseIdentifier,
                                                                           for: indexPath) as! ChatSectionHeaderView
                view.setTitle(title)
                return view
            case .none, .loading:
                return nil
            }
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

            switch section {
            case .none, .messages:
                let layoutSection: NSCollectionLayoutSection = .flexibleListItemSection(height: 60)
                layoutSection.interGroupSpacing = spacing
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                        heightDimension: .absolute(ChatSectionHeaderView.Height))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                         elementKind: UICollectionView.elementKindSectionHeader,
                                                                         alignment: .top)
                layoutSection.boundarySupplementaryItems = [header]
                
                return layoutSection
            case .loading:
                return .listItemSection(height: 50)
            }
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ChatViewController {
    enum Section: Hashable {
        case messages(title: String)
        case loading
    }
    
    enum Item: Hashable {
        case textMessage(configuration: TextMessageUIConfiguration)
        case imageBase64Message(configuration: ImageBase64MessageUIConfiguration)
        case imageDataMessage(configuration: ImageDataMessageUIConfiguration)
        case unsupportedMessage(configuration: UnsupportedMessageUIConfiguration)
        case remoteContentMessage(configuration: RemoteConfigMessageUIConfiguration)
        case channelFeed(configuration: ChannelFeedUIConfiguration)
        case loading
        
        var message: MessagingChatMessageDisplayInfo? {
            switch self {
            case .textMessage(let configuration):
                return configuration.message
            case .imageBase64Message(let configuration):
                return configuration.message
            case .imageDataMessage(let configuration):
                return configuration.message
            case .unsupportedMessage(let configuration):
                return configuration.message
            case .remoteContentMessage(let configuration):
                return configuration.message
            case .channelFeed, .loading:
                return nil
            }
        }
    }
    
    struct TextMessageUIConfiguration: Hashable {
        
        let message: MessagingChatMessageDisplayInfo
        let textMessageDisplayInfo: MessagingChatMessageTextTypeDisplayInfo
        let isGroupChatMessage: Bool
        var actionCallback: (ChatMessageAction)->()
        var externalLinkHandleCallback: ChatMessageLinkPressedCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.message.id == rhs.message.id &&
            lhs.message.deliveryState == rhs.message.deliveryState
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(message.id)
            hasher.combine(message.deliveryState)
        }
    }

    struct ImageBase64MessageUIConfiguration: Hashable {
        
        let message: MessagingChatMessageDisplayInfo
        let imageMessageDisplayInfo: MessagingChatMessageImageBase64TypeDisplayInfo
        let isGroupChatMessage: Bool
        var actionCallback: (ChatMessageAction)->()
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.message.id == rhs.message.id &&
            lhs.message.deliveryState == rhs.message.deliveryState
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(message.id)
            hasher.combine(message.deliveryState)
        }
    }
    
    struct ImageDataMessageUIConfiguration: Hashable {
        
        let message: MessagingChatMessageDisplayInfo
        let imageMessageDisplayInfo: MessagingChatMessageImageDataTypeDisplayInfo
        let isGroupChatMessage: Bool
        var actionCallback: (ChatMessageAction)->()
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.message.id == rhs.message.id &&
            lhs.message.deliveryState == rhs.message.deliveryState
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(message.id)
            hasher.combine(message.deliveryState)
        }
    }
    
    struct UnsupportedMessageUIConfiguration: Hashable {
        let message: MessagingChatMessageDisplayInfo
        let isGroupChatMessage: Bool
        let pressedCallback: EmptyCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.message.id == rhs.message.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(message.id)
        }
    }
    
    struct RemoteConfigMessageUIConfiguration: Hashable {
        let message: MessagingChatMessageDisplayInfo
        let isGroupChatMessage: Bool
        let pressedCallback: EmptyCallback
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.message.id == rhs.message.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(message.id)
        }
    }
    
    struct ChannelFeedUIConfiguration: Hashable {
        
        let feed: MessagingNewsChannelFeed
        var actionCallback: (ChatFeedAction)->()
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.feed == rhs.feed
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(feed)
        }
    }

    enum ChatMessageAction: Hashable {
        case resend
        case delete
        case unencrypted
    }
    
    enum ChatFeedAction: Hashable {
        case learnMore(URL)
    }
    
    enum State {
        case loading
        case chat
        case viewChannel
        case joinChannel
        case otherUserIsBlocked
        case userIsBlocked
        case cantContactUser(ableToInvite: Bool)
    }
    
    struct NavButtonConfiguration {
        let actions: [Action]
    
        struct Action {
            let type: ActionType
            let callback: EmptyCallback
        }
        
        enum ActionType {
            case viewProfile, block, viewInfo, leave, copyAddress
            
            var title: String {
                switch self {
                case .viewProfile:
                    return String.Constants.viewProfile.localized()
                case .block:
                    return String.Constants.block.localized()
                case .viewInfo:
                    return String.Constants.viewInfo.localized()
                case .leave:
                    return String.Constants.leave.localized()
                case .copyAddress:
                    return String.Constants.copyAddress.localized()
                }
            }
            
            var icon: UIImage {
                switch self {
                case .viewProfile, .viewInfo:
                    return .arrowUpRight
                case .block:
                    return .systemMultiplyCircle
                case .leave:
                    return .systemRectangleArrowRight
                case .copyAddress:
                    return .systemDocOnDoc
                }
            }
            
            var isDestructive: Bool {
                switch self {
                case .viewProfile, .viewInfo, .copyAddress:
                    return false
                case .block, .leave:
                    return true
                }
            }
        }
    }
}

private extension ChatViewController {
    struct ScrollingInfo {
        let prevContentHeight: CGFloat
        let contentOffsetBeforeUpdate: CGPoint
        
        init(collectionView: UICollectionView) {
            prevContentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
            contentOffsetBeforeUpdate = collectionView.contentOffset
        }
    }
}
