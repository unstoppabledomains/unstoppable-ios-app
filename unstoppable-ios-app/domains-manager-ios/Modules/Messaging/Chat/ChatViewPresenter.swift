//
//  ChatViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

@MainActor
protocol ChatViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var analyticsName: Analytics.ViewName { get }

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
protocol ChatPresenterContentIdentifiable {
    var chatId: String? { get }
    var channelId: String? { get }
}

@MainActor
final class ChatViewPresenter {
    
    private weak var view: (any ChatViewProtocol)?
    private let profile: MessagingChatUserProfileDisplayInfo
    private var conversationState: MessagingChatConversationState
    private let fetchLimit: Int = 30
    private var messages: [MessagingChatMessageDisplayInfo] = []
    private var isLoadingMessages = false
    private var blockStatus: MessagingPrivateChatBlockingStatus = .unblocked
    private var isChannelEncrypted: Bool = true
    private var didLoadTime = Date()
    
    var analyticsName: Analytics.ViewName { .chatDialog }

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
        
        if messageIndex >= (messages.count - Constants.numberOfUnreadMessagesBeforePrefetch),
           let last = messages.last,
           !last.isFirstInChat {
            loadMoreMessagesBefore(message: last)
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
            logButtonPressedAnalyticEvents(button: .unblock)
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
}

// MARK: - ChatPresenterContentIdentifiable
extension ChatViewPresenter: ChatPresenterContentIdentifiable {
    var chatId: String? {
        switch conversationState {
        case .existingChat(let chat):
            return chat.id
        case .newChat:
            return nil
        }
    }
    var channelId: String? { nil }
}

// MARK: - MessagingServiceListener
extension ChatViewPresenter: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats(let chats, let profile):
                if profile.id == self.profile.id,
                   case .existingChat(let chat) = conversationState,
                   let updatedChat = chats.first(where: { $0.id == chat.id }),
                   let lastMessage = updatedChat.lastMessage,
                   messages.first(where: { $0.id == lastMessage.id }) == nil {
                    self.conversationState = .existingChat(updatedChat)
                    loadAndShowData()
                }
            case .messagesAdded(let messages, let chatId):
                if case .existingChat(let chat) = conversationState,
                   chatId == chat.id,
                   !messages.isEmpty {
                    await self.addMessages(messages)
                    showData(animated: true, scrollToBottomAnimated: true, isLoading: isLoadingMessages)
                    loadMoreMessagesBefore(message: messages.last!)
                }
            case .messageUpdated(let updatedMessage, var newMessage):
                if case .existingChat(let chat) = conversationState,
                   updatedMessage.chatId == chat.id,
                   let i = self.messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    await newMessage.prepareToDisplay()
                    self.messages[i] = newMessage
                    await addMessages([])
                    showData(animated: false, isLoading: isLoadingMessages)
                }
            case .messagesRemoved(let messages, let chatId):
                if case .existingChat(let chat) = conversationState,
                   chatId == chat.id {
                    let removedIds = messages.map { $0.id }
                    self.messages = self.messages.filter({ !removedIds.contains($0.id) })
                    showData(animated: true, isLoading: isLoadingMessages)
                }
            case .channels, .channelFeedAdded, .refreshOfUserProfile, .messageReadStatusUpdated:
                return
            }
        }
    }
}

// MARK: - Private functions
private extension ChatViewPresenter {
    func loadAndShowData() {
        Task {
            view?.setLoading(active: true)
            do {
                switch conversationState {
                case .existingChat(let chat):
                    isLoadingMessages = true
                    let cachedMessages = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                                  before: nil,
                                                                                                  cachedOnly: true,
                                                                                                  limit: fetchLimit)
                    await addMessages(cachedMessages)
                    showData(animated: false, scrollToBottomAnimated: false, isLoading: false)
                    
                    updateUIForChatApprovedStateAsync()
                    isChannelEncrypted = await appContext.messagingService.isMessagesEncryptedIn(conversation: conversationState)
                    let updateMessages = try await appContext.messagingService.getMessagesForChat(chat,
                                                                                                  before: nil,
                                                                                                  cachedOnly: false,
                                                                                                  limit: fetchLimit)
                    await addMessages(updateMessages)
                    showData(animated: true, isLoading: false)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.view?.setLoading(active: false)
                        self.isLoadingMessages = false
                    }
                case .newChat:
                    isChannelEncrypted = await appContext.messagingService.isMessagesEncryptedIn(conversation: conversationState)
                    await updateUIForChatApprovedState()
                    view?.setLoading(active: false)
                    view?.startTyping()
                    showData(animated: false, isLoading: false)
                }
            } catch {
                view?.showAlertWith(error: error, handler: nil)
                view?.setLoading(active: false)
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
                                                                                              cachedOnly: false,
                                                                                              limit: fetchLimit)
                await addMessages(unreadMessages)
                isLoadingMessages = false
            } catch {
                view?.showAlertWith(error: error, handler: nil)
                isLoadingMessages = false
            }
            showData(animated: false, isLoading: false)
        }
    }
    
    func addMessages(_ messages: [MessagingChatMessageDisplayInfo]) async {
        for message in messages {
            var message = message
            await message.prepareToDisplay()
            if let i = self.messages.firstIndex(where: { $0.id == message.id }) {
                self.messages[i] = message
            } else {
                self.messages.append(message)
            }
        }
        
        self.messages.sort(by: { $0.time > $1.time })
    }
    
    func awaitForUIReady() async {
        let timeSinceViewDidLoad = Date().timeIntervalSince(didLoadTime)
        let uiReadyTime = CNavigationController.animationDuration + 0.3
        
        let dif = uiReadyTime - timeSinceViewDidLoad
        if dif > 0 {
            try? await Task.sleep(seconds: dif)
        }
    }
    
    func showData(animated: Bool, scrollToBottomAnimated: Bool, isLoading: Bool) {
        showData(animated: animated, isLoading: isLoading, completion: { [weak self] in
            self?.view?.scrollToTheBottom(animated: scrollToBottomAnimated)
        })
    }
    
    @MainActor
    func showData(animated: Bool, isLoading: Bool, completion: EmptyCallback? = nil) {
        var snapshot = ChatSnapshot()
        
        if messages.isEmpty {
            if isLoading {
                view?.setEmptyState(nil)
            } else {
                view?.setEmptyState(isChannelEncrypted ? .chatEncrypted : .chatUnEncrypted)
            }
            view?.setScrollEnabled(false)
            snapshot.appendSections([])
        } else {
            view?.setEmptyState(nil)
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
        let isGroupChatMessage = conversationState.isGroupConversation
        
        switch message.type {
        case .text(let textMessageDisplayInfo):
            return .textMessage(configuration: .init(message: message,
                                                     textMessageDisplayInfo: textMessageDisplayInfo,
                                                     isGroupChatMessage: isGroupChatMessage,
                                                     actionCallback: { [weak self] action in
                self?.handleChatMessageAction(action, forMessage: message)
            }))
        case .imageBase64(let imageMessageDisplayInfo):
            return .imageBase64Message(configuration: .init(message: message,
                                                            imageMessageDisplayInfo: imageMessageDisplayInfo,
                                                            isGroupChatMessage: isGroupChatMessage,
                                                            actionCallback: { [weak self] action in
                self?.handleChatMessageAction(action, forMessage: message)
            }))
        case .unknown:
            return .unsupportedMessage(configuration: .init(message: message,
                                                            isGroupChatMessage: isGroupChatMessage,
                                                            pressedCallback: { [weak self] in
                self?.logButtonPressedAnalyticEvents(button: .downloadUnsupportedMessage)
                self?.shareContentOfMessage(message)
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
            let domainName = await appContext.dataAggregatorService.getReverseResolutionDomain(for: profile.wallet.normalized)
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
                actions.append(.init(type: .viewProfile, callback: { [weak self] in
                    self?.logButtonPressedAnalyticEvents(button: .viewMessagingProfile)
                    self?.didPressViewDomainProfileButton(domainName: domainName)
                }))
            } else {
                return // No actions
            }
        case .existingChat(let chat):
            switch chat.type {
            case .private(let details):
                if let domainName = details.otherUser.domainName {
                    actions.append(.init(type: .viewProfile, callback: { [weak self] in
                        self?.logButtonPressedAnalyticEvents(button: .viewMessagingProfile)
                        self?.didPressViewDomainProfileButton(domainName: domainName)
                    }))
                }
                
                switch blockStatus {
                case .unblocked, .currentUserIsBlocked:
                    actions.append(.init(type: .block, callback: { [weak self] in
                        self?.logButtonPressedAnalyticEvents(button: .block)
                        self?.didPressBlockButton()
                    }))
                case .bothBlocked, .otherUserIsBlocked:
                    Void()
                }
            case .group(let groupDetails):
                actions.append(.init(type: .viewInfo, callback: { [weak self] in
                    self?.logButtonPressedAnalyticEvents(button: .viewGroupChatInfo)
                    self?.didPressViewGroupInfoButton(groupDetails: groupDetails)
                }))
                
                if !groupDetails.isUserAdminWith(wallet: profile.wallet) {
                    actions.append(.init(type: .leave, callback: { [weak self] in
                        self?.logButtonPressedAnalyticEvents(button: .leaveGroup)
                        self?.didPressLeaveButton()
                    }))
                }
            }
        }
        
        view?.setupRightBarButton(with: .init(actions: actions))
    }
    
    func didPressViewDomainProfileButton(domainName: String) {
        let link = String.Links.domainProfilePage(domainName: domainName)
        view?.openLink(link)
    }
    
    func didPressViewGroupInfoButton(groupDetails: MessagingGroupChatDetails) {
        Task {
            guard let view else { return }
            
            await appContext.pullUpViewService.showGroupChatInfoPullUp(groupChatDetails: groupDetails, in: view)
        }
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
        guard case .existingChat(let chat) = conversationState else { return }

        Task {
            do {
                view?.setLoading(active: true)
                try await appContext.messagingService.leaveGroupChat(chat)
                view?.cNavigationController?.popViewController(animated: true)
            } catch {
                view?.showAlertWith(error: error, handler: nil)
            }
            view?.setLoading(active: false)
        }
    }
    
    func setOtherUser(blocked: Bool) {
        guard case .existingChat(let chat) = conversationState else { return }

        Task {
            do {
                view?.setLoading(active: true)
                try await appContext.messagingService.setUser(in: chat, blocked: blocked)
                await updateUIForChatApprovedState()
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
            logButtonPressedAnalyticEvents(button: .resendMessage)
            Task { try? await appContext.messagingService.resendMessage(message) }
        case .delete:
            logButtonPressedAnalyticEvents(button: .deleteMessage)
            appContext.messagingService.deleteMessage(message)
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: i)
                showData(animated: true, isLoading: isLoadingMessages)
            }
        case .unencrypted:
            guard let view else { return }
            
            appContext.pullUpViewService.showUnencryptedMessageInfoPullUp(in: view)
        }
    }
    
    func updateUIForChatApprovedStateAsync() {
        Task {
            await updateUIForChatApprovedState()
        }
    }
    
    func updateUIForChatApprovedState() async {
        guard case .existingChat(let chat) = conversationState else {
            self.view?.setUIState(.chat)
            return
        }
        
        if case .group = chat.type {
            self.view?.setUIState(.chat)
            return
        }
        
        if let blockStatus = try? await appContext.messagingService.getBlockingStatusForChat(chat) {
            self.blockStatus = blockStatus
            switch blockStatus {
            case .unblocked:
                self.view?.setUIState(.chat)
            case .currentUserIsBlocked:
                self.view?.setUIState(.userIsBlocked)
            case .otherUserIsBlocked, .bothBlocked:
                self.view?.setUIState(.otherUserIsBlocked)
            }
            await awaitForUIReady()
            setupBarButtons()
        }
    }
    
    func shareContentOfMessage(_ message: MessagingChatMessageDisplayInfo) {
        Task {
            guard let contentURL = await appContext.messagingService.decryptedContentURLFor(message: message) else { return } // TODO: - Handle error
            
            let activityViewController = UIActivityViewController(activityItems: [contentURL], applicationActivities: nil)
            activityViewController.completionWithItemsHandler = { _, completed, _, _ in
                if completed {
                    AppReviewService.shared.appReviewEventDidOccurs(event: .didShareProfile)
                }
            }
            view?.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Images related methods
private extension ChatViewPresenter {
    func didPickImageToSend(_ image: UIImage) {
        let resizedImage = image.resized(to: Constants.maxImageResolution) ?? image
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
        logAnalytic(event: .willSendMessage,
                    parameters: [.messageType: type.analyticName])
        Task {
            do {
                var newMessage: MessagingChatMessageDisplayInfo
                switch conversationState {
                case .existingChat(let chat):
                    if !chat.isApproved {
                        try await approveChatRequest(chat)
                    }
                    newMessage = try await appContext.messagingService.sendMessage(type,
                                                                                   isEncrypted: isChannelEncrypted,
                                                                                   in: chat)
                case .newChat(let userInfo):
                    let (chat, message) = try await appContext.messagingService.sendFirstMessage(type,
                                                                                                 to: userInfo,
                                                                                                 by: profile)
                    self.conversationState = .existingChat(chat)
                    newMessage = message
                }
                await newMessage.prepareToDisplay()
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
