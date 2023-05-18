//
//  ChatViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

@MainActor
protocol ChatViewProtocol: BaseCollectionViewControllerProtocol {
    func applySnapshot(_ snapshot: ChatSnapshot, animated: Bool)
    func startTyping()
    func setInputText(_ text: String)
    func setPlaceholder(_ placeholder: String)
    func setTitleOfType(_ titleType: ChatTitleView.TitleType)
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
}

// MARK: - ChatViewProtocol
extension ChatViewController: ChatViewProtocol {
    func applySnapshot(_ snapshot: ChatSnapshot, animated: Bool) {
        dataSource.apply(snapshot, animatingDifferences: animated)
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
}

// MARK: - UICollectionViewDelegate
extension ChatViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        presenter.didSelectItem(item)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
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
//        presenter.didAdjustTextHeight()
    }
}

// MARK: - Private functions
private extension ChatViewController {
    func calculateCollectionBottomInset() {
        let keyboardHeight = isKeyboardOpened ? keyboardFrame.height : 0
        collectionView.contentInset.bottom = chatInputView.bounds.height + keyboardHeight + 12
    }
}

// MARK: - Setup functions
private extension ChatViewController {
    func setup() {
        setupInputView()
        setupNavBar()
        setupCollectionView()
    }
    
    func setupInputView() {
        chatInputView.frame.origin.x = 0
        chatInputView.frame.origin.y = self.view.bounds.height - ChatInputView.height
        chatInputView.delegate = self
        chatInputView.setPlaceholder("Message as sandy.nft...")
    }
    
    func setupNavBar() {
        titleView = ChatTitleView()
        navigationItem.titleView = titleView 
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.collectionViewLayout = buildLayout()
        collectionView.contentInset.top = 50

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
    }
    
    func buildLayout() -> UICollectionViewLayout {
        let spacing: CGFloat = UICollectionView.SideOffset
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = spacing
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: {
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let layout: NSCollectionLayoutSection = .flexibleListItemSection(height: 60)
            layout.interGroupSpacing = spacing
            
            return layout
        }, configuration: config)
        layout.register(CollectionReusableRoundedBackground.self, forDecorationViewOfKind: CollectionReusableRoundedBackground.reuseIdentifier)
        
        return layout
    }
}

// MARK: - Collection elements
extension ChatViewController {
    enum Section: Hashable {
        case messages
    }
    
    enum Item: Hashable {
        case textMessage(configuration: TextMessageUIConfiguration)
    }
    
    struct TextMessageUIConfiguration: Hashable {
        let message: ChatTextMessage
    }
}
