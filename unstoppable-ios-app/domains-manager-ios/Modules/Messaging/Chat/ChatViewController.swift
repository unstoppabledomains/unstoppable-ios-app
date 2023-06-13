//
//  ChatViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

@MainActor
protocol ChatViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ChatSnapshot, animated: Bool, completion: EmptyCallback?)
    func startTyping()
    func setInputText(_ text: String)
    func setPlaceholder(_ placeholder: String)
    func setTitleOfType(_ titleType: ChatTitleView.TitleType)
    func scrollToTheBottom(animated: Bool)
    func scrollToItem(_ item: ChatViewController.Item, animated: Bool)
}

typealias ChatDataSource = UICollectionViewDiffableDataSource<ChatViewController.Section, ChatViewController.Item>
typealias ChatSnapshot = NSDiffableDataSourceSnapshot<ChatViewController.Section, ChatViewController.Item>

@MainActor
final class ChatViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet private weak var chatInputView: ChatInputView!
    private var titleView: ChatTitleView!

    override var scrollableContentYOffset: CGFloat? { 13 }
    var cellIdentifiers: [UICollectionViewCell.Type] { [ChatTextCell.self] }
    var presenter: ChatViewPresenterProtocol!
    private var dataSource: ChatDataSource!
    private var scrollingInfo: ScrollingInfo?
    override var isObservingKeyboard: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setup()
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cNavigationBar?.navBarContentView.setTitleView(hidden: false, animated: true)
        presenter.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        hideKeyboard()
    }
    
    override func keyboardWillShowAction(duration: Double, curve: Int, keyboardHeight: CGFloat) {
        scrollToTheBottom(animated: true)
    }
}

// MARK: - ChatViewProtocol
extension ChatViewController: ChatViewProtocol {
    func applySnapshot(_ snapshot: ChatSnapshot, animated: Bool, completion: EmptyCallback?) {
        scrollingInfo = ScrollingInfo(collectionView: collectionView)
        dataSource.apply(snapshot, animatingDifferences: animated, completion: { [weak self] in
            self?.scrollingInfo = nil
            completion?()
        })
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
        
        scrollTo(indexPath: indexPath, at: .bottom, animated: animated)
    }
    
    func scrollToItem(_ item: Item, animated: Bool) {
        guard let indexPath = dataSource.indexPath(for: item) else { return }

        scrollTo(indexPath: indexPath, at: .top, animated: animated)
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
        if let scrollingInfo {
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
        presenter.didPressSendText(text)
    }
    
    func chatInputViewDidAdjustContentHeight(_ chatInputView: ChatInputView) {
        calculateCollectionBottomInset()
    }
}

// MARK: - Private functions
private extension ChatViewController {
    func calculateCollectionBottomInset() {
        let keyboardHeight = isKeyboardOpened ? keyboardFrame.height : 0
        collectionView.contentInset.bottom = chatInputView.bounds.height + keyboardHeight + 12
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
}

// MARK: - Setup functions
private extension ChatViewController {
    func setup() {
        setupInputView()
        setupNavBar()
        setupCollectionView()
        setupHideKeyboardTap()
    }
    
    func setupInputView() {
        chatInputView.frame.origin.x = 0
        chatInputView.frame.origin.y = self.view.bounds.height - ChatInputView.height
        chatInputView.setTopBorderHidden(true, animated: false)
        chatInputView.delegate = self
    }
    
    func setupNavBar() {
        titleView = ChatTitleView()
        navigationItem.titleView = titleView 
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 50
        collectionView.showsVerticalScrollIndicator = true
        collectionView.register(ChatSectionHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: ChatSectionHeaderView.reuseIdentifier)

        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = ChatDataSource.init(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            switch item {
            case .textMessage(let configuration):
                let cell = collectionView.dequeueCellOfType(ChatTextCell.self, forIndexPath: indexPath)
                cell.setWith(configuration: configuration)
                
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
            case .none:
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
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layoutSection: NSCollectionLayoutSection = .flexibleListItemSection(height: 60)
            layoutSection.interGroupSpacing = spacing
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                    heightDimension: .absolute(ChatSectionHeaderView.Height))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            layoutSection.boundarySupplementaryItems = [header]
            
            return layoutSection
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ChatViewController {
    enum Section: Hashable {
        case messages(title: String)
    }
    
    enum Item: Hashable {
        case textMessage(configuration: TextMessageUIConfiguration)
        
        var message: MessagingChatMessageDisplayInfo {
            switch self {
            case .textMessage(let configuration):
                return configuration.message
            }
        }
    }
    
    struct TextMessageUIConfiguration: Hashable {
        
        let message: MessagingChatMessageDisplayInfo
        let textMessageDisplayInfo: MessagingChatMessageTextTypeDisplayInfo
        var actionCallback: (ChatMessageAction)->()
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.message == rhs.message &&
            lhs.textMessageDisplayInfo == rhs.textMessageDisplayInfo
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(message)
            hasher.combine(textMessageDisplayInfo)
        }
    }
    
    enum ChatMessageAction: Hashable {
        case resend
        case delete
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
