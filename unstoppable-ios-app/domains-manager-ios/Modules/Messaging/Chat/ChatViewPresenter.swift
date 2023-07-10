//
//  ChatViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

@MainActor
protocol ChatViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: ChatViewController.Item)
    func willDisplayItem(_ item: ChatViewController.Item)
    
    func didTypeText(_ text: String)
    func didPressSendText(_ text: String)
    
    func approveButtonPressed()
    func secondaryButtonPressed()
    
    func choosePhotoButtonPressed()
    func takePhotoButtonPressed()
}

extension ChatViewPresenterProtocol {
    func didTypeText(_ text: String) { }
    func didPressSendText(_ text: String) { }
    func approveButtonPressed() { }
    func secondaryButtonPressed() { }
    func choosePhotoButtonPressed() { }
    func takePhotoButtonPressed() { }
}

@MainActor
final class ChatViewPresenter {
    
    private weak var view: (any ChatViewProtocol)?
    private let profile: MessagingChatUserProfileDisplayInfo
    private var conversationState: MessagingChatConversationState
    private let fetchLimit: Int = 30
    private var messages: [MessagingChatMessageDisplayInfo] = []
    private var chatState: ChatContentState = .upToDate
    private var isLoadingMessages = false
    private var blockStatus: MessagingPrivateChatBlockingStatus = .unblocked
    
    init(view: any ChatViewProtocol,
         profile: MessagingChatUserProfileDisplayInfo,
         conversationState: MessagingChatConversationState) {
        self.view = view
        self.profile = profile
        self.conversationState = conversationState
    }
}

// MARK: - ChatViewPresenterProtocol
extension ChatViewPresenter: ChatViewPresenterProtocol {
    func viewDidLoad() {
        appContext.messagingService.addListener(self)
        view?.setUIState(.loading)
        setupTitle()
        setupPlaceholder()
        setupBarButtons()
        loadAndShowData()
        updateUIForChatApprovedState()
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
         
    }
    
    func willDisplayItem(_ item: ChatViewController.Item) {
        guard let message = item.message,
              case .existingChat(let chat) = conversationState else { return }
        
        guard let messageIndex = messages.firstIndex(where: { $0.id == message.id }) else {
            Debugger.printFailure("Failed to find will display message with id \(message.id) in the list", critical: true)
            return }
    
        if !message.isRead {
            messages[messageIndex].isRead = true
            try? appContext.messagingService.markMessage(message, isRead: true, wallet: chat.thisUserDetails.wallet)
        }
        
        if messageIndex >= (messages.count - Constants.numberOfUnreadMessagesBeforePrefetch) {
            switch chatState {
            case .hasUnloadedMessagesBefore(let message):
                loadMoreMessagesBefore(message: message)
            case .upToDate:
                return
            case .hasUnreadMessagesAfter:
                return
            }
        }
    }
    
    func didTypeText(_ text: String) {
        
    }
    
    func didPressSendText(_ text: String) {
        guard !text.trimmedSpaces.isEmpty else { return }
        
        view?.setInputText("")
        sendTextMesssage(text)
    }
     
    func approveButtonPressed() { }
    
    func secondaryButtonPressed() {
        switch blockStatus {
        case .unblocked, .currentUserIsBlocked:
            return
        case .otherUserIsBlocked, .bothBlocked:
            didPressUnblockButton()
        }
    }
    
    func choosePhotoButtonPressed() {
        view?.hideKeyboard()
        guard let view else { return  }
        
        UnstoppableImagePicker.shared.pickImage(in: view, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImageToSend(image)
            }
        })
    }
    
    func takePhotoButtonPressed() {
        view?.hideKeyboard()
        guard let view else { return  }
        
        UnstoppableImagePicker.shared.selectFromCamera(in: view, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImageToSend(image)
            }
        })
    }
    
    func choosePhotoButtonPressed() {
        view?.hideKeyboard()
        guard let view else { return  }
        
        UnstoppableImagePicker.shared.pickImage(in: view, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImageToSend(image)
            }
        })
    }
    
    func takePhotoButtonPressed() {
        view?.hideKeyboard()
        guard let view else { return  }
        
        UnstoppableImagePicker.shared.selectFromCamera(in: view, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImageToSend(image)
            }
        })
    }
}

// MARK: - MessagingServiceListener
extension ChatViewPresenter: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats, .channels:
                return
            case .messagesAdded(let messages, let chatId):
                if case .existingChat(let chat) = conversationState,
                   chatId == chat.id {
                    self.addMessages(messages)
                    checkIfUpToDate()
                    showData(animated: true, scrollToBottomAnimated: true, isLoading: isLoadingMessages)
                }
            case .messageUpdated(let updatedMessage, let newMessage):
                if case .existingChat(let chat) = conversationState,
                   updatedMessage.chatId == chat.id,
                   let i = self.messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    self.messages[i] = newMessage
                    checkIfUpToDate()
                    showData(animated: false, isLoading: isLoadingMessages)
                }
            case .messagesRemoved(let messages, let chatId):
                if case .existingChat(let chat) = conversationState,
                   chatId == chat.id {
                    let removedIds = messages.map { $0.id }
                    self.messages = self.messages.filter({ !removedIds.contains($0.id) })
                    checkIfUpToDate()
                    showData(animated: true, isLoading: isLoadingMessages)
                }
            }
        }
    }
}

// MARK: - Private functions
private extension ChatViewPresenter {
    func loadAndShowData() {
        Task {
            do {
                switch conversationState {
                case .existingChat(let chat):
                    isLoadingMessages = true
                    view?.setLoading(active: true)
                    let messagesBefore = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                                  before: nil,
                                                                                                  limit: fetchLimit)
                    addMessages(messagesBefore)
                    
                    if !(messages.first?.isRead == true),
                       let firstReadMessage = messages.first(where: { $0.isRead }) {
                        self.chatState = .hasUnreadMessagesAfter(message: firstReadMessage)
                    } else {
                        checkIfUpToDate()
                    }
                    
                    switch chatState {
                    case .upToDate, .hasUnloadedMessagesBefore:
                        showData(animated: false, scrollToBottomAnimated: false, isLoading: false)
                    case .hasUnreadMessagesAfter(let message):
                        let unreadMessages = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                                      after: message,
                                                                                                      limit: fetchLimit)
                        addMessages(unreadMessages)
                        showData(animated: false, isLoading: false, completion: {
                            if let message = unreadMessages.last {
                                let item = self.createSnapshotItemFrom(message: message)
                                self.view?.scrollToItem(item, animated: false)
                            }
                        })
                        checkIfUpToDate()
                    }
                    DispatchQueue.main.async {
                        self.view?.setLoading(active: false)
                        self.updateUIForChatApprovedState()
                    }
                    isLoadingMessages = false
                case .newChat:
                    updateUIForChatApprovedState()
                    view?.startTyping()
                    showData(animated: false, isLoading: false)
                }
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
            }
        }
    }
    
    func loadMoreMessagesBefore(message: MessagingChatMessageDisplayInfo) {
        guard !isLoadingMessages,
              case .existingChat(let chat) = conversationState else { return }
        
        isLoadingMessages = true
        showData(animated: false, isLoading: true)
        Task {
            do {
                let unreadMessages = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                              before: message,
                                                                                              limit: fetchLimit)
                addMessages(unreadMessages)
                checkIfUpToDate()
                isLoadingMessages = false
            } catch {
                view?.showAlertWith(error: error, handler: nil) // TODO: - Handle error
                isLoadingMessages = false
            }
            showData(animated: false, isLoading: false)
        }
    }
    
    func checkIfUpToDate() {
        guard !messages.isEmpty else {
            chatState = .upToDate
            return
        }
         if messages.last!.isFirstInChat {
            self.chatState = .upToDate
        } else {
            self.chatState = .hasUnloadedMessagesBefore(message: messages.last!)
        }
    }
    
    func addMessages(_ messages: [MessagingChatMessageDisplayInfo]) {
        for message in messages {
            if let i = self.messages.firstIndex(where: { $0.id == message.id }) {
                self.messages[i] = message
            } else {
                self.messages.append(message)
            }
        }
        
        self.messages.sort(by: { $0.time > $1.time })
    }
    
    func showData(animated: Bool, scrollToBottomAnimated: Bool, isLoading: Bool) {
        showData(animated: animated, isLoading: isLoading, completion: { [weak self] in
            self?.view?.scrollToTheBottom(animated: scrollToBottomAnimated)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.view?.scrollToTheBottom(animated: scrollToBottomAnimated)
            }
        })
    }
    
    @MainActor
    func showData(animated: Bool, isLoading: Bool, completion: EmptyCallback? = nil) {
        var snapshot = ChatSnapshot()
        
        if messages.isEmpty {
            view?.setScrollEnabled(false)
            snapshot.appendSections([.emptyState])
            snapshot.appendItems([.emptyState])
        } else {
            if isLoading {
                snapshot.appendSections([.loading])
                snapshot.appendItems([.loading])
            }
            view?.setScrollEnabled(true)
            let groupedMessages = [Date : [MessagingChatMessageDisplayInfo]].init(grouping: messages, by: { $0.time.dayStart })
            let sortedDates = groupedMessages.keys.sorted(by: { $0 < $1 })
            
            for date in sortedDates {
                let messages = groupedMessages[date] ?? []
                let title = MessageDateFormatter.formatMessagesSectionDate(date)
                snapshot.appendSections([.messages(title: title)])
                snapshot.appendItems(messages.sorted(by: { $0.time < $1.time }).map({ createSnapshotItemFrom(message: $0) }))
            }
        }
        
        view?.applySnapshot(snapshot, animated: animated, completion: completion)
    }
    
    func createSnapshotItemFrom(message: MessagingChatMessageDisplayInfo) -> ChatViewController.Item {
        switch message.type {
        case .text(let textMessageDisplayInfo):
            return .textMessage(configuration: .init(message: message, textMessageDisplayInfo: textMessageDisplayInfo, actionCallback: { [weak self] action in
                self?.handleChatMessageAction(action, forMessage: message)
            }))
        case .imageBase64(let imageMessageDisplayInfo):
            return .imageBase64Message(configuration: .init(message: message, imageMessageDisplayInfo: imageMessageDisplayInfo, actionCallback: { [weak self] action in
                self?.handleChatMessageAction(action, forMessage: message)
            }))
        }
    }
    
    func setupTitle() {
        switch conversationState {
        case .existingChat(let chat):
            switch chat.type {
            case .private(let chatDetails):
                let otherUser = chatDetails.otherUser
                setupTitleFor(userInfo: otherUser)
            case .group(let groupDetails):
                view?.setTitleOfType(.group(groupDetails))
            }
        case .newChat(let userInfo):
            setupTitleFor(userInfo: userInfo)
        }
    }
    
    func setupTitleFor(userInfo: MessagingChatUserDisplayInfo) {
        if let domainName = userInfo.domainName {
            view?.setTitleOfType(.domainName(domainName))
        } else {
            view?.setTitleOfType(.walletAddress(userInfo.wallet))
        }
    }
    
    func setupPlaceholder() {
        Task {
            let domainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: profile.wallet)
            let sender = domainName ?? profile.wallet.walletAddressTruncated
            let placeholder = String.Constants.chatInputPlaceholderAsDomain.localized(sender)
            view?.setPlaceholder(placeholder)
        }
    }
    
    func setupBarButtons() {
        var actions: [ChatViewController.NavButtonConfiguration.Action] = []
        
        switch conversationState {
        case .newChat(let userInfo):
            if let domainName = userInfo.domainName {
                actions.append(.init(type: .viewProfile, callback: { [weak self] in self?.didPressViewDomainProfileButton(domainName: domainName) }))
            } else {
                return // No actions
            }
        case .existingChat(let chat):
            switch chat.type {
            case .private(let details):
                if let domainName = details.otherUser.domainName {
                    actions.append(.init(type: .viewProfile, callback: { [weak self] in self?.didPressViewDomainProfileButton(domainName: domainName) }))
                }
                
                switch blockStatus {
                case .unblocked, .currentUserIsBlocked:
                    actions.append(.init(type: .block, callback: { [weak self] in self?.didPressBlockButton() }))
                case .bothBlocked, .otherUserIsBlocked:
                    Void()
                }
            case .group:
                actions.append(.init(type: .leave, callback: { [weak self] in self?.didPressLeaveButton() }))
            }
        }
        
        view?.setupRightBarButton(with: .init(actions: actions))
    }
    
    func didPressViewDomainProfileButton(domainName: String) {
        let link = String.Links.domainProfilePage(domainName: domainName)
        view?.openLink(link)
    }
    
    func didPressBlockButton() {
        Task {
            do {
                guard let view else { return }
                
                try await appContext.pullUpViewService.showMessagingBlockConfirmationPullUp(blockUserName: conversationState.userInfo?.displayName ?? "",
                                                                                            in: view)
                await view.dismissPullUpMenu()
                setOtherUser(blocked: true)
            } catch { }
        }
    }
    
    func didPressUnblockButton() {
        setOtherUser(blocked: false)
    }
    
    func didPressLeaveButton() {
        // TODO: - Implement when SDK is ready
    }
    
    func setOtherUser(blocked: Bool) {
        guard case .existingChat(let chat) = conversationState else { return }

        Task {
            do {
                view?.setLoading(active: true)
                try await appContext.messagingService.setUser(in: chat, blocked: blocked)
                await refreshBlockStatus()
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
            
            view?.setLoading(active: false)
        }
    }
    
    func handleChatMessageAction(_ action: ChatViewController.ChatMessageAction,
                                 forMessage message: MessagingChatMessageDisplayInfo) {
        switch action {
        case .resend:
            Task { try? await appContext.messagingService.resendMessage(message) }
        case .delete:
            appContext.messagingService.deleteMessage(message)
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: i)
                showData(animated: true, isLoading: isLoadingMessages)
            }
        }
    }
    
    func updateUIForChatApprovedState() {
        self.view?.setUIState(.chat)
        Task {
            await refreshBlockStatus()
        }
    }
    
    func refreshBlockStatus() async {
        guard case .existingChat(let chat) = conversationState else { return }

        if case .group = chat.type {
            return
        }
        
        if let blockStatus = try? await appContext.messagingService.getBlockingStatusForChat(chat) {
            self.blockStatus = blockStatus
            switch blockStatus {
            case .unblocked:
                return
            case .currentUserIsBlocked:
                self.view?.setUIState(.userIsBlocked)
            case .otherUserIsBlocked, .bothBlocked:
                self.view?.setUIState(.otherUserIsBlocked)
            }
            setupBarButtons()
        }
    }
}

// MARK: - Images related methods
private extension ChatViewPresenter {
    func didPickImageToSend(_ image: UIImage) {
        let resizedImage = image.resized(to: 1000) ?? image
        sendImageMessage(resizedImage)
    }
}

// MARK: - Images related methods
private extension ChatViewPresenter {
    func didPickImageToSend(_ image: UIImage) {
        let resizedImage = image.resized(to: 1000) ?? image
        sendImageMessage(resizedImage)
    }
}

// MARK: - Send message
private extension ChatViewPresenter {
    func sendTextMesssage(_ text: String) {
        let textTypeDetails = MessagingChatMessageTextTypeDisplayInfo(text: text,
                                                                      encryptedText: text)
        let messageType = MessagingChatMessageDisplayType.text(textTypeDetails)
        sendMessageOfType(messageType)
    }
    
    func sendImageMessage(_ image: UIImage) {
        guard let base64 = image.base64String else { return }
        let preparedBase64 = Base64DataTransformer.addingImageIdentifier(to: base64)
        let imageTypeDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: preparedBase64,
                                                                              encryptedContent: preparedBase64)
        sendMessageOfType(.imageBase64(imageTypeDetails))
    }
    
    func sendMessageOfType(_ type: MessagingChatMessageDisplayType) {
        Task {
            do {
                let newMessage: MessagingChatMessageDisplayInfo
                switch conversationState {
                case .existingChat(let chat):
                    if !chat.isApproved {
                        try await approveChatRequest(chat)
                    }
                    newMessage = try await appContext.messagingService.sendMessage(type, in: chat)
                case .newChat(let userInfo):
                    let (chat, message) = try await appContext.messagingService.sendFirstMessage(type,
                                                                                                 to: userInfo,
                                                                                                 by: profile)
                    self.conversationState = .existingChat(chat)
                    newMessage = message
                }
                messages.insert(newMessage, at: 0)
                showData(animated: true, scrollToBottomAnimated: true, isLoading: isLoadingMessages)
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
        }
    }
    
    func approveChatRequest(_ chat: MessagingChatDisplayInfo) async throws {
        var chat = chat
        view?.setLoading(active: true)
        do {
            try await appContext.messagingService.makeChatRequest(chat, approved: true)
            chat.isApproved = true
            self.conversationState = .existingChat(chat)
            view?.setLoading(active: false)
        } catch {
            view?.setLoading(active: false)
            throw error
        }
    }
}

// MARK: - Private methods
private extension ChatViewPresenter {
    enum ChatContentState {
        case upToDate
        case hasUnloadedMessagesBefore(message: MessagingChatMessageDisplayInfo)
        case hasUnreadMessagesAfter(message: MessagingChatMessageDisplayInfo)
    }
}
