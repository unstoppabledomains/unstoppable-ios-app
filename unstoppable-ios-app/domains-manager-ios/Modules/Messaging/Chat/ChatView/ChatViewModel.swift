//
//  ChatViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject, ViewAnalyticsLogger {
    
    typealias LoadMoreMessagesTask = Task<[MessagingChatMessageDisplayInfo], Error>
    
    private let profile: MessagingChatUserProfileDisplayInfo
    private let messagingService: MessagingServiceProtocol
    private let featureFlagsService: UDFeatureFlagsServiceProtocol
    private(set) var conversationState: MessagingChatConversationState
    @Published private(set) var isLoadingMessages = false
    @Published private(set) var blockStatus: MessagingPrivateChatBlockingStatus = .unblocked
    @Published private(set) var isChannelEncrypted: Bool = true
    @Published private(set) var isAbleToContactUser: Bool = true
    @Published private(set) var messages: [MessagingChatMessageDisplayInfo] = []
    @Published private(set) var listOfGroupParticipants: [MessagingChatUserDisplayInfo] = []
    @Published private(set) var scrollToMessage: MessagingChatMessageDisplayInfo?
    @Published private(set) var messagesCache: Set<MessagingChatMessageDisplayInfo> = []
    @Published private(set) var isLoading = false
    @Published private(set) var chatState: ChatView.ChatState = .loading
    @Published private(set) var canSendAttachments = true
    @Published private(set) var placeholder: String = ""
    @Published private(set) var navActions: [ChatView.NavAction] = []
    @Published private(set) var titleType: ChatNavTitleView.TitleType = .walletAddress("")
    @Published private(set) var suggestingUsers: [MessagingChatUserDisplayInfo] = []
    @Published private(set) var messageToReply: MessagingChatMessageDisplayInfo? 
    
    @Published var input: String = ""
    @Published var keyboardFocused: Bool = false
    @Published var error: Error?
    var isGroupChatMessage: Bool { conversationState.isGroupConversation }
    var isAbleToReply: Bool { isGroupChatMessage }
    
    var analyticsName: Analytics.ViewName { .chatDialog }
    
    private var router: HomeTabRouter
    private let serialQueue = DispatchQueue(label: "com.unstoppable.chat.view.serial")
    private var messagesToReactions: [String : Set<MessageReactionDescription>] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private var loadMoreMessagesTask: LoadMoreMessagesTask?

    init(profile: MessagingChatUserProfileDisplayInfo,
         conversationState: MessagingChatConversationState,
         router: HomeTabRouter,
         messagingService: MessagingServiceProtocol = appContext.messagingService,
         featureFlagsService: UDFeatureFlagsServiceProtocol = appContext.udFeatureFlagsService) {
        self.profile = profile
        self.conversationState = conversationState
        self.router = router
        self.messagingService = messagingService
        self.featureFlagsService = featureFlagsService
        
        
        messagingService.addListener(self)
        featureFlagsService.addListener(self)
        $keyboardFocused.sink { [weak self] isActive in
            if isActive {
                self?.scrollToBottom()
            }
        }.store(in: &cancellables)
        $messageToReply.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.setIfUserCanSendAttachments()
            }
        }.store(in: &cancellables)
        chatState = .loading
        setupTitle()
        setupPlaceholder()
        setIfUserCanSendAttachments()
        loadAndShowData()
        setListOfGroupParticipants()
    }
    
}

// MARK: - Open methods
extension ChatViewModel {
    func willDisplayMessage(_ message: MessagingChatMessageDisplayInfo) {
        guard case .existingChat(let chat) = conversationState else { return }
        
        guard let messageIndex = messages.firstIndex(where: { $0.id == message.id }) else {
            Debugger.printFailure("Failed to find will display message with id \(message.id) in the list", critical: true)
            return }
        
        if !message.isRead {
            messages[messageIndex].isRead = true
            try? messagingService.markMessage(message, isRead: true, wallet: chat.thisUserDetails.wallet)
        }
        
        if messageIndex >= (messages.count - Constants.numberOfUnreadMessagesBeforePrefetch),
           let last = getLatestMessageToLoadMore() {
            loadMoreMessagesBefore(message: last)
        }
    }
    
    func sendPressed() {
        let text = input.trimmedSpaces
        guard !text.isEmpty else { return }
        
        input = ""
        sendTextMesssage(text)
    }
    
    func didPressUnblockButton() {
        Task {
            if case .existingChat(let chat) = conversationState,
               case .private(let details) = chat.type {
                _ = (try? await setUser(details.otherUser, in: chat, blocked: true))
            }
        }
    }
    
    func additionalActionPressed(_ action: MessageInputView.AdditionalAction) {
        switch action {
        case .takePhoto:
            takePhotoButtonPressed()
        case .choosePhoto:
            choosePhotoButtonPressed()
        }
    }
    
    func handleChatMessageAction(_ action: Chat.ChatMessageAction) {
        guard case .existingChat(let chat) = conversationState else { return }
        
        switch action {
        case .resend(let message):
            logButtonPressedAnalyticEvents(button: .resendMessage)
            Task { try? await messagingService.resendMessage(message, in: chat) }
        case .delete(let message):
            logButtonPressedAnalyticEvents(button: .deleteMessage)
            Task { try? await messagingService.deleteMessage(message, in: chat) }
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: i)
            }
        case .unencrypted:
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            
            appContext.pullUpViewService.showUnencryptedMessageInfoPullUp(in: view)
        case .viewSenderProfile(let sender):
            Task {
                let wallet = sender.userDisplayInfo.wallet
                var domainName = sender.userDisplayInfo.domainName
                if domainName == nil {
                    domainName = (try? await NetworkService().fetchGlobalReverseResolution(for: wallet.lowercased()))?.name
                }
                if let domainName,
                   domainName.isValidDomainName() {
                    UDVibration.buttonTap.vibrate()
                    didPressViewDomainProfileButton(domainName: domainName, walletAddress: wallet)
                }
            }
        case .copyText(let text):
            logButtonPressedAnalyticEvents(button: .copyChatMessageToClipboard)
            UIPasteboard.general.string = text
            Vibration.success.vibrate()
        case .saveImage(let image):
            logButtonPressedAnalyticEvents(button: .saveChatImage)
            let saver = PhotoLibraryImageSaver()
            saver.saveImage(image)
        case .showImage(let image):
            logButtonPressedAnalyticEvents(button: .viewMessagePhoto)
            showMessageImageViewWith(image: image, mode: .view)
        case .blockUserInGroup(let user):
            logButtonPressedAnalyticEvents(button: .blockUserInGroupChat,
                                           parameters: [.chatId : chat.id,
                                                        .wallet: user.wallet])
            Task {
                try? await setUser(user, in: chat, blocked: true)
            }
        case .sendReaction(let content, let toMessage):
            logButtonPressedAnalyticEvents(button: .sendReaction, parameters: [.value: content])
            sendReactionMessage(content, toMessage: toMessage)
        case .reply(let message):
            logButtonPressedAnalyticEvents(button: .replyToMessage)
            messageToReply = message
            keyboardFocused = true
        }
    }
    
    func handleExternalLinkPressed(_ url: URL, by sender: MessagingChatSender) {
        verifyAndHandleExternalLink(url, by: sender)
    }
    
    func showMentionSuggestionsIfNeeded() {
        let listOfGroupParticipants = listOfGroupParticipants
        guard !listOfGroupParticipants.isEmpty,
              let lastComponent = input.components(separatedBy: " ").last,
              let mention = MessageMentionString(string: lastComponent) else {
            suggestingUsers = []
            return
        }
        
        showMentionSuggestions(using: listOfGroupParticipants,
                               mention: mention)
    }
    
    func didSelectMentionSuggestion(user: MessagingChatUserDisplayInfo) {
        if let nameForMention = user.nameForMention,
           let mention = MessageMentionString.makeMentionFrom(string: nameForMention) {
            replaceCurrentInputWithSelectedMention(mention)
        }
    }
    
    func didTapJumpToReplyButton() {
        scrollToMessage = messageToReply
    }
    
    func didTapRemoveReplyButton() {
        messageToReply = nil
    }
    
    func getReferenceMessageWithId(_ messageId: String) -> MessagingChatMessageDisplayInfo? {
        if let message = messages.first(where: { $0.id == messageId }) {
            return message
        } else {
            return nil
        }
    }
    
    func didTapJumpToMessage(_ message: MessagingChatMessageDisplayInfo) {
        scrollToMessage = message
    }
}

// MARK: - Private methods
private extension ChatViewModel {
    func getEarliestMessageInCache() -> MessagingChatMessageDisplayInfo? {
        messagesCache.lazy.sorted(by: { $0.time > $1.time }).last
    }
    
    func getLatestMessageToLoadMore() -> MessagingChatMessageDisplayInfo? {
        if let message = getEarliestMessageInCache(),
           !message.isFirstInChat {
            return message
        }
        return nil
    }
    
    func showMentionSuggestions(using listOfGroupParticipants: [MessagingChatUserDisplayInfo],
                                mention: MessageMentionString) {
        let mentionUsername = mention.mentionWithoutPrefix.lowercased()
        if mentionUsername.isEmpty {
            suggestingUsers = listOfGroupParticipants
        } else {
            suggestingUsers = listOfGroupParticipants.filter {
                let nameForMention = $0.nameForMention
                let isMentionFullyTyped = nameForMention == mentionUsername
                let isUsernameContainMention = nameForMention?.contains(mentionUsername) == true
                return isUsernameContainMention && !isMentionFullyTyped
            }
        }
    }
    
    func replaceCurrentInputWithSelectedMention(_ mention: MessageMentionString) {
        let separator = " "
        var userInput = input.components(separatedBy: separator).dropLast()
        userInput.append(mention.mentionWithPrefix)
        input = userInput.joined(separator: separator)
        suggestingUsers.removeAll()
    }
    
    func verifyAndHandleExternalLink(_ url: URL, by sender: MessagingChatSender) {
        if let domainName = parseMentionDomainNameFrom(url: url) {
            logButtonPressedAnalyticEvents(button: .mentionWithinMessage, parameters: [.value: domainName])
            handleMentionPressedTo(domainName: domainName)
        } else {
            logButtonPressedAnalyticEvents(button: .linkWithinMessage)
            handleOtherLinkPressed(url, by: sender)
        }
    }
    
    func handleMentionPressedTo(domainName: String) {
        Task {
            guard let presentationDetails = await DomainProfileLinkValidator.getShowDomainProfilePresentationDetailsFor(domainName: domainName, params: nil) else { return }
            
            UDVibration.buttonTap.vibrate()
            await showDomainProfileWith(presentationDetails: presentationDetails)
        }
    }
    
    func parseMentionDomainNameFrom(url: URL) -> String? {
        let string = url.absoluteString
        return MessageMentionString(string: string)?.mentionWithoutPrefix
    }
    
    func handleOtherLinkPressed(_ url: URL, by sender: MessagingChatSender) {
        guard case .existingChat(let chat) = conversationState else { return }
        
        keyboardFocused = false
        
        switch sender {
        case .thisUser:
            openLinkOrDomainProfile(url)
        case .otherUser(let otherUser):
            handleLinkFromOtherUserPressed(url,
                                           in: chat,
                                           by: otherUser)
        }
    }
    
    func handleLinkFromOtherUserPressed(_ url: URL,
                                        in chat: MessagingChatDisplayInfo,
                                        by otherUser: MessagingChatUserDisplayInfo) {
        guard let view = appContext.coreAppCoordinator.topVC else { return }

        Task {
            do {
                let action = try await appContext.pullUpViewService.showHandleChatLinkSelectionPullUp(in: view)
                await view.dismissPullUpMenu()
                
                switch action {
                case .handle:
                    openLinkOrDomainProfile(url)
                case .block:
                    try await setUser(otherUser, in: chat, blocked: true)
                    view.cNavigationController?.popViewController(animated: true)
                }
            } catch { }
        }
    }
    
//    func blockUser(_ user: MessagingChatUserDisplayInfo)
    
    func choosePhotoButtonPressed() {
        keyboardFocused = false
        guard let view = appContext.coreAppCoordinator.topVC else { return  }
        
        UnstoppableImagePicker.shared.pickImage(in: view, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImageToSend(image)
            }
        })
    }
    
    func takePhotoButtonPressed() {
        keyboardFocused = false
        guard let view = appContext.coreAppCoordinator.topVC else { return  }
        
        UnstoppableImagePicker.shared.selectFromCamera(in: view, imagePickerCallback: { [weak self] image in
            DispatchQueue.main.async {
                self?.didPickImageToSend(image)
            }
        })
    }
    
    func setListOfGroupParticipants() {
        if case .existingChat(let chat) = conversationState {
            switch chat.type {
            case .private:
                return
            case .group(let messagingGroupChatDetails):
                setListOfGroupParticipantsFrom(users: messagingGroupChatDetails.members)
            case .community(let messagingCommunitiesChatDetails):
                setListOfGroupParticipantsFrom(users: messagingCommunitiesChatDetails.members)
            }
        }
    }
    
    func setListOfGroupParticipantsFrom(users: [MessagingChatUserDisplayInfo]) {
        self.listOfGroupParticipants = users
    }
    
    func setupTitle() {
        switch conversationState {
        case .existingChat(let chat):
            switch chat.type {
            case .private(let chatDetails):
                let otherUser = chatDetails.otherUser
                setupTitleFor(userInfo: otherUser)
            case .group(let groupDetails):
                titleType = .group(groupDetails)
            case .community(let communityDetails):
                titleType = .community(communityDetails)
            }
        case .newChat(let description):
            setupTitleFor(userInfo: description.userInfo)
        }
    }
    
    func setupTitleFor(userInfo: MessagingChatUserDisplayInfo) {
        if let domainName = userInfo.anyDomainName {
            titleType = .domainName(domainName)
        } else {
            titleType = .walletAddress(userInfo.wallet)
        }
    }
    
    func setupPlaceholder() {
        Task {
            let wallets = messagingService.fetchWalletsAvailableForMessaging()
            let userWallet = wallets.first(where: { $0.address.normalized == profile.wallet.normalized })
            let sender = userWallet?.rrDomain?.name ?? profile.wallet.walletAddressTruncated
            let placeholder = String.Constants.chatInputPlaceholderAsDomain.localized(sender)
            self.placeholder = placeholder
        }
    }
    
    func setIfUserCanSendAttachments() {
        let isReplying = self.messageToReply != nil
        let isProfileHasDomain = appContext.walletsDataService.wallets.findWithAddress(profile.wallet)?.rrDomain != nil
        if !isReplying,
           isProfileHasDomain {
            if isCommunityChat() {
                let isCommunityMediaEnabled = featureFlagsService.valueFor(flag: .communityMediaEnabled)
                canSendAttachments = isCommunityMediaEnabled
            } else {
                canSendAttachments = true
            }
        } else {
            canSendAttachments = false
        }
    }
    
    func loadAndShowData() {
        Task {
            isLoading = true
            let fetchLimit = ChatConstants.fetchLimit
            do {
                switch conversationState {
                case .existingChat(let chat):
                    isLoadingMessages = true
                    let cachedMessages = try await messagingService.getMessagesForChat(chat,
                                                                                       before: nil,
                                                                                       cachedOnly: true,
                                                                                       limit: fetchLimit)
                    await addMessages(cachedMessages, scrollToBottom: true)
                    isChannelEncrypted = try await messagingService.isMessagesEncryptedIn(conversation: conversationState)
                    await updateUIForChatApprovedState()
                    let updateMessages = try await messagingService.getMessagesForChat(chat,
                                                                                       before: nil,
                                                                                       cachedOnly: false,
                                                                                       limit: fetchLimit)
                    isLoadingMessages = false
                    await addMessages(updateMessages, scrollToBottom: true)
                    try await loadMoreInitialMessagesIfNeeded(in: chat)
                    isLoading = false
                case .newChat:
                    isChannelEncrypted = try await messagingService.isMessagesEncryptedIn(conversation: conversationState)
                    await updateUIForChatApprovedState()
                    isLoading = false
                }
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    func loadMoreInitialMessagesIfNeeded(in chat: MessagingChatDisplayInfo, startTime: Date = Date()) async throws {
        guard isNeedToLoadMoreInitialMessages(),
            let earliestMessage = getEarliestMessageInCache(),
            !shouldBreakLoadMoreLoopDueToTimeout(startTime: startTime) else { return }
        
        let messages = try await createTaskAndLoadMoreMessagesIn(chat: chat,
                                                                 beforeMessage: earliestMessage)
        await addMessages(messages, scrollToBottom: true)
        try await loadMoreInitialMessagesIfNeeded(in: chat, startTime: startTime) // Call recursively until sufficient number of visible messages is loaded
    }
    
    func shouldBreakLoadMoreLoopDueToTimeout(startTime: Date) -> Bool {
        Date().timeIntervalSince(startTime) > ChatConstants.loadMoreMessagesLimitSec
    }
    
    func isNeedToLoadMoreInitialMessages() -> Bool {
        // Number of visible messages (not including reactions, system messages, etc.) should be at least 20
        messages.count < ChatConstants.minRequiredNumberOfVisibleMessagesOnLaunch &&
        !didReachFirstMessageInChat()
    }
    
    func didReachFirstMessageInChat() -> Bool {
        getEarliestMessageInCache()?.isFirstInChat == true
    }
    
    func loadMoreMessagesBefore(message: MessagingChatMessageDisplayInfo) {
        guard !isLoadingMessages,
              case .existingChat(let chat) = conversationState else { return }
        
        isLoadingMessages = true
        Task {
            do {
                let unreadMessages = try await createTaskAndLoadMoreMessagesIn(chat: chat,
                                                                               beforeMessage: message)
                
                await addMessages(unreadMessages, scrollToBottom: false)
            } catch {
                self.error = error
            }
            
            isLoadingMessages = false
        }
    }
    
    func createTaskAndLoadMoreMessagesIn(chat: MessagingChatDisplayInfo,
                                         beforeMessage: MessagingChatMessageDisplayInfo) async throws -> [MessagingChatMessageDisplayInfo] {
        if let loadMoreMessagesTask {
            return try await loadMoreMessagesTask.value
        }
        let task: Task<[MessagingChatMessageDisplayInfo], Error> = Task {
            try await messagingService.getMessagesForChat(chat,
                                                          before: beforeMessage,
                                                          cachedOnly: false,
                                                          limit: ChatConstants.fetchLimit)
        }
        self.loadMoreMessagesTask = task
        let result = try await task.value
        loadMoreMessagesTask = nil
        return result
    }
   
    func reloadCachedMessages() {
        Task {
            if case .existingChat(let chat) = conversationState {
                let cachedMessages = try await messagingService.getMessagesForChat(chat,
                                                                                   before: nil,
                                                                                   cachedOnly: true,
                                                                                   limit: ChatConstants.fetchLimit)
                await addMessages(cachedMessages, scrollToBottom: false)
            }
        }
    }
    
    @MainActor
    func addMessages(_ messages: [MessagingChatMessageDisplayInfo],
                     scrollToBottom: Bool) async {
        messagesCache.formUnion(messages)
        
        let messages = serialQueue.sync {
            messages.filter { message in
                switch message.type {
                case .reaction(let info):
                    let counter = MessageReactionDescription(content: info.content,
                                                             messageId: message.id,
                                                             referenceMessageId: info.messageId,
                                                             isUserReaction: message.senderType.isThisUser)
                    _ = messagesToReactions[info.messageId, default: []].insert(counter)
                    if !message.isRead,
                       case .existingChat(let chat) = conversationState {
                        try? messagingService.markMessage(message, isRead: true, wallet: chat.thisUserDetails.wallet)
                    }
                    return false
                case .unsupported:
                    return false
                default:
                    return true
                }
            }
        }
        
        for message in messages {
            var message = message
            await message.prepareToDisplay()
            if let i = self.messages.firstIndex(where: { $0.id == message.id }) {
                self.messages[i] = message
            } else {
                self.messages.append(message)
            }
            loadRemoteContentOfMessageAsync(message)
        }
        if let communityChatDetails = getCommunityChatDetails() {
            if !featureFlagsService.valueFor(flag: .communityMediaEnabled) {
                // Filter media attachments
                self.messages = self.messages.filter({ message in
                    switch message.type {
                    case .text:
                        return true
                    default:
                        return false
                    }
                })
            }
            
            self.messages = self.messages.filter { !communityChatDetails.blockedUsersList.contains($0.senderType.userDisplayInfo.wallet.normalized) }
        }
        
        for (i, message) in self.messages.enumerated() {
            self.messages[i].reactions = Array(messagesToReactions[message.id] ?? [])
        }
        
        self.messages.sort(by: { $0.time > $1.time })
        
        if scrollToBottom {
            await waitBeforeScroll()
            self.scrollToBottom()
            await waitBeforeScroll()
        }
    }
    
    func waitBeforeScroll() async {
        await Task.sleep(seconds: 0.1)
    }
    
    func loadRemoteContentOfMessageAsync(_ message: MessagingChatMessageDisplayInfo) {
        guard case .remoteContent = message.type,
              case .existingChat(let chat) = conversationState else { return }
        
        Task {
            do {
                let updatedMessage = try await messagingService.loadRemoteContentFor(message,
                                                                                     in: chat)
                if let i = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    messages[i] = updatedMessage
                }
            } catch {
                await Task.sleep(seconds: 5)
                loadRemoteContentOfMessageAsync(message)
            }
        }
    }
    
    func getCommunityChatDetails() -> MessagingCommunitiesChatDetails? {
        switch conversationState {
        case .existingChat(let chat):
            switch chat.type {
            case .community(let details):
                return details
            case .private, .group:
                return nil
            }
        case .newChat:
            return nil
        }
    }
    
    func isCommunityChat() -> Bool {
        getCommunityChatDetails() != nil
    }
    
    
    func updateUIForChatApprovedStateAsync() {
        Task {
            await updateUIForChatApprovedState()
        }
    }
    
    func updateUIForChatApprovedState() async {
        switch conversationState {
        case .existingChat(let chat):
            if case .group = chat.type {
                chatState = .chat
                return
            }
            
            if let blockStatus = try? await messagingService.getBlockingStatusForChat(chat) {
                self.blockStatus = blockStatus
                switch blockStatus {
                case .unblocked:
                    chatState = .chat
                case .currentUserIsBlocked:
                    chatState = .userIsBlocked
                case .otherUserIsBlocked, .bothBlocked:
                    chatState = .otherUserIsBlocked
                }
            }
        case .newChat(let newConversationDescription):
            func prepareToChat() {
                chatState = .chat
                DispatchQueue.main.async {
                    self.keyboardFocused = true
                }
            }
            
            if !messagingService.canContactWithoutProfileIn(newConversation: newConversationDescription) {
                do {
                    let canContact = try await messagingService.isAbleToContactUserIn(newConversation: newConversationDescription,
                                                                                      by: profile)
                    if canContact {
                        prepareToChat()
                    } else {
                        isAbleToContactUser = false
                        chatState = .cantContactUser
                    }
                } catch {
                    self.error = error
                }
            } else {
                prepareToChat()
            }
        }
        await setupBarButtons()
    }
    
    func scrollToBottom() {
        scrollToMessage = messages.first
    }
}

// MARK: - Actions
private extension ChatViewModel {
    private func setupBarButtons() async {
        var actions: [ChatView.NavAction] = []
        
        func addCopyAddressActionFor(userInfo: MessagingChatUserDisplayInfo) {
            actions.append(.init(type: .copyAddress, callback: { [weak self] in
                                    self?.logButtonPressedAnalyticEvents(button: .copyWalletAddress)
                CopyWalletAddressPullUpHandler.copyToClipboard(address: userInfo.wallet, ticker: BlockchainType.Ethereum.rawValue)
            }))
        }
        
        func addViewProfileActionIfPossibleFor(userInfo: MessagingChatUserDisplayInfo) async {
            if let domainName = userInfo.domainName {
                let canViewProfile: Bool = domainName.isValidDomainName()
                
                if canViewProfile  {
                    actions.append(.init(type: .viewProfile, callback: { [weak self] in
                                                    self?.logButtonPressedAnalyticEvents(button: .viewMessagingProfile)
                        self?.didPressViewDomainProfileButton(domainName: domainName,
                                                              walletAddress: userInfo.wallet)
                    }))
                } else {
                    addCopyAddressActionFor(userInfo: userInfo)
                }
            } else {
                addCopyAddressActionFor(userInfo: userInfo)
            }
        }
        
        switch conversationState {
        case .newChat(let description):
            await addViewProfileActionIfPossibleFor(userInfo: description.userInfo)
        case .existingChat(let chat):
            switch chat.type {
            case .private(let details):
                await addViewProfileActionIfPossibleFor(userInfo: details.otherUser)
                
                if messagingService.canBlockUsers(in: chat) {
                    switch blockStatus {
                    case .unblocked, .currentUserIsBlocked:
                        actions.append(.init(type: .block, callback: { [weak self] in
                                                            self?.logButtonPressedAnalyticEvents(button: .block)
                            self?.didPressBlockPrivateChatButton(user: details.otherUser, chat: chat)
                        }))
                    case .bothBlocked, .otherUserIsBlocked:
                        Void()
                    }
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
            case .community(let details):
                actions.append(.init(type: .viewInfo, callback: { [weak self] in
                                            self?.logButtonPressedAnalyticEvents(button: .viewCommunityInfo,
                                                                                 parameters: [.communityName: details.displayName])
                    self?.didPressViewCommunityInfoButton(communityDetails: details)
                }))
                
                if !details.blockedUsersList.isEmpty {
                    actions.append(.init(type: .blockedUsers, callback: { [weak self] in
                                                    self?.logButtonPressedAnalyticEvents(button: .viewBlockedUsersList,
                                                                                         parameters: [.communityName: details.displayName])
                        self?.didPressViewBlockedUsersListButton(communityDetails: details,
                                                                 in: chat)
                    }))
                }
                
                if details.isJoined {
                    actions.append(.init(type: .leaveCommunity, callback: { [weak self] in
                                                    self?.logButtonPressedAnalyticEvents(button: .leaveCommunity,
                                                                                         parameters: [.communityName: details.displayName])
                        self?.didPressLeaveCommunity(chat: chat)
                    }))
                } else {
                    actions.append(.init(type: .joinCommunity, callback: { [weak self] in
                                                    self?.logButtonPressedAnalyticEvents(button: .joinCommunity,
                                                                                         parameters: [.communityName: details.displayName])
                        self?.didPressJoinCommunity(chat: chat)
                    }))
                }
            }
        }
        
        self.navActions = actions
    }
    
    
    func didPressJoinCommunity(chat: MessagingChatDisplayInfo) {
        Task {
            do {
                let updatedChat = try await messagingService.joinCommunityChat(chat)
                self.conversationState = .existingChat(updatedChat)
                await setupBarButtons()
            } catch {
                self.error = error
            }
        }
    }
    
    func didPressLeaveCommunity(chat: MessagingChatDisplayInfo) {
        Task {
            isLoading = true
            do {
                _ = try await messagingService.leaveCommunityChat(chat)
                router.chatTabNavPath.removeLast()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func didPressViewDomainProfileButton(domainName: String,
                                         walletAddress: String) {
        guard let wallet = appContext.walletsDataService.wallets.findWithAddress(profile.wallet) else { return }
        router.showPublicDomainProfile(of: .init(walletAddress: walletAddress,
                                                 name: domainName),
                                       by: wallet)
    }
    
    func didPressViewGroupInfoButton(groupDetails: MessagingGroupChatDetails) {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }
            
            await appContext.pullUpViewService.showGroupChatInfoPullUp(groupChatDetails: groupDetails,
                                                                       by: profile,
                                                                       in: view)
        }
    }
    
    func didPressViewCommunityInfoButton(communityDetails: MessagingCommunitiesChatDetails) {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }

            await appContext.pullUpViewService.showCommunityChatInfoPullUp(communityDetails: communityDetails,
                                                                           by: profile,
                                                                           in: view)
        }
    }
    
    func didPressViewBlockedUsersListButton(communityDetails: MessagingCommunitiesChatDetails,
                                            in chat: MessagingChatDisplayInfo) {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }

            await appContext.pullUpViewService.showCommunityBlockedUsersListPullUp(communityDetails: communityDetails,
                                                                                   by: profile,
                                                                                   unblockCallback: { [weak self] user in
                self?.didPressUnblockGroupChat(user: user, in: chat)
            },
                                                                                   in: view)
        }
    }
    
    func didPressUnblockGroupChat(user: MessagingChatUserDisplayInfo,
                                  in chat: MessagingChatDisplayInfo) {
        Task {
            guard let view = appContext.coreAppCoordinator.topVC else { return }

            if let chat = try? await setUser(user, in: chat, blocked: false),
               case .community(let communityDetails) = chat.type {
                if communityDetails.blockedUsersList.isEmpty {
                    await view.dismissPullUpMenu()
                } else {
                    didPressViewBlockedUsersListButton(communityDetails: communityDetails, in: chat)
                }
            }
        }
    }
    
    func didPressBlockPrivateChatButton(user: MessagingChatUserDisplayInfo,
                                        chat: MessagingChatDisplayInfo) {
        Task {
            do {
                guard let view = appContext.coreAppCoordinator.topVC else { return }

                try await appContext.pullUpViewService.showMessagingBlockConfirmationPullUp(blockUserName: conversationState.userInfo?.displayName ?? "",
                                                                                            in: view)
                await view.dismissPullUpMenu()
                _ = (try? await setUser(user, in: chat, blocked: true))
            } catch { }
        }
    }
    
    func didPressLeaveButton() {
        guard case .existingChat(let chat) = conversationState else { return }
        
        Task {
            do {
                isLoading = true
                try await messagingService.leaveGroupChat(chat)
                router.chatTabNavPath.removeLast()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    @discardableResult
    func setUser(_ user: MessagingChatUserDisplayInfo,
                 in chat: MessagingChatDisplayInfo,
                 blocked: Bool) async throws -> MessagingChatDisplayInfo? {
        isLoading = true

        do {
            let updatedChat: MessagingChatDisplayInfo?
            switch chat.type {
            case .private:
                updatedChat = try await setPrivateChatUser(blocked: blocked,
                                                           in: chat)
            case .group, .community:
                updatedChat = try await setGroupChatUser(user, blocked: blocked, chat: chat)
            }
            await updateUIForChatApprovedState()
            isLoading = false
            return updatedChat
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
    
    @discardableResult
    func setPrivateChatUser(blocked: Bool,
                            in chat: MessagingChatDisplayInfo) async throws -> MessagingChatDisplayInfo? {
        try await messagingService.setUser(in: .chat(chat), blocked: blocked)
        return nil
    }
    
    @discardableResult
    func setGroupChatUser(_ otherUser: MessagingChatUserDisplayInfo,
                          blocked: Bool,
                          chat: MessagingChatDisplayInfo) async throws -> MessagingChatDisplayInfo? {
        switch chat.type {
        case .group:
            try await messagingService.setUser(in: .userInGroup(otherUser, chat), blocked: blocked)
            return chat
        case .community(var details):
            var blockedUsersList = details.blockedUsersList
            try await messagingService.setUser(in: .userInGroup(otherUser, chat), blocked: blocked)
            let otherUserWallet = otherUser.wallet.normalized
            if blocked {
                blockedUsersList.append(otherUserWallet)
            } else {
                blockedUsersList.removeAll(where: { $0 == otherUserWallet })
            }
            details.blockedUsersList = blockedUsersList
            var chat = chat
            chat.type = .community(details)
            self.conversationState = .existingChat(chat)
            if blocked {
                await addMessages([], scrollToBottom: false)
            } else {
                await addMessages(Array(messagesCache), scrollToBottom: false)
            }
            return chat
        case .private:
            return nil
        }
    }
    
    func openLinkOrDomainProfile(_ url: URL) {
        Task {
            if let presentationDetails = await DomainProfileLinkValidator.getShowDomainProfilePresentationDetailsFor(url: url) {
                await showDomainProfileWith(presentationDetails: presentationDetails)
            } else {
                appContext.coreAppCoordinator.topVC?.openLink(.generic(url: url.absoluteString))
            }
        }
    }
    
    func showDomainProfileWith(presentationDetails: DomainProfileLinkValidator.ShowDomainProfilePresentationDetails) async {
        switch presentationDetails {
        case .showUserDomainProfile(let domain, let wallet, let action):
            await router.showDomainProfile(domain,
                                           wallet: wallet,
                                           preRequestedAction: action,
                                           shouldResetNavigation: false,
                                           dismissCallback: nil)
        case .showPublicDomainProfile(let publicDomainDisplayInfo, let wallet, let action):
            router.showPublicDomainProfile(of: publicDomainDisplayInfo,
                                           by: wallet,
                                           preRequestedAction: action)
        }
    }
}

// MARK: - Images related methods
private extension ChatViewModel {
    func didPickImageToSend(_ image: UIImage) {
        let resizedImage = image.resized(to: Constants.maxImageResolution) ?? image
        showMessageImageViewWith(image: resizedImage, mode: .confirmSending(callback: { [weak self] in
            self?.sendImageMessage(resizedImage)
        }))
    }
    
    func showMessageImageViewWith(image: UIImage, mode: MessagingImageView.Mode) {
        let messagingImageVC = MessagingImageView.instantiate(mode: mode, image: image)
        appContext.coreAppCoordinator.topVC?.present(messagingImageVC, animated: true)
    }
}

// MARK: - Send message
private extension ChatViewModel {
    func sendTextMesssage(_ text: String) {
        let textTypeDetails = MessagingChatMessageTextTypeDisplayInfo(text: text)
        let messageType = MessagingChatMessageDisplayType.text(textTypeDetails)
        wrapMessageInReplyIfNeededAndSend(messageType: messageType)
    }
    
    func sendReactionMessage(_ content: String, toMessage: MessagingChatMessageDisplayInfo) {
        let reactionTypeDetails = MessagingChatMessageReactionTypeDisplayInfo(content: content, messageId: toMessage.id)
        let messageType = MessagingChatMessageDisplayType.reaction(reactionTypeDetails)
        sendMessageOfType(messageType)
    }
    
    func sendImageMessage(_ image: UIImage) {
        guard let data = image.dataToUpload else { return }
        let imageTypeDetails = MessagingChatMessageImageDataTypeDisplayInfo(data: data, image: image)
        sendMessageOfType(.imageData(imageTypeDetails))
    }
    
    func wrapMessageInReplyIfNeededAndSend(messageType: MessagingChatMessageDisplayType) {
        if let messageToReply {
            let replyDetails = MessagingChatMessageReplyTypeDisplayInfo(contentType: messageType,
                                                                        messageId: messageToReply.id)
            let replyType = MessagingChatMessageDisplayType.reply(replyDetails)
            sendMessageOfType(replyType)
        } else {
            sendMessageOfType(messageType)
        }
    }
    
    func sendMessageOfType(_ type: MessagingChatMessageDisplayType) {
        logAnalytic(event: .willSendMessage,
                    parameters: [.messageType: type.analyticName])
        self.messageToReply = nil
        Task {
            do {
                var newMessage: MessagingChatMessageDisplayInfo
                switch conversationState {
                case .existingChat(let chat):
                    if !chat.isApproved {
                        try await approveChatRequest(chat)
                    }
                    newMessage = try await messagingService.sendMessage(type,
                                                                        isEncrypted: isChannelEncrypted,
                                                                        in: chat)
                case .newChat(let newConversationDescription):
                    isLoading = true
                    let (chat, message) = try await messagingService.sendFirstMessage(type,
                                                                                      to: newConversationDescription,
                                                                                      by: profile)
                    self.conversationState = .existingChat(chat)
                    newMessage = message
                    isLoading = false
                }
                if case .reaction = newMessage.type {
                    await addMessages([newMessage], scrollToBottom: false)
                } else {
                    await newMessage.prepareToDisplay()
                    messages.insert(newMessage, at: 0)
                    scrollToMessage = newMessage
                    messagesCache.insert(newMessage)
                }
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
    
    func approveChatRequest(_ chat: MessagingChatDisplayInfo) async throws {
        var chat = chat
        isLoading = true
        do {
            try await messagingService.makeChatRequest(chat, approved: true)
            chat.isApproved = true
            self.conversationState = .existingChat(chat)
            isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }
}


// MARK: - MessagingServiceListener
extension ChatViewModel: MessagingServiceListener {
    nonisolated func messagingDataTypeDidUpdated(_ messagingDataType: MessagingDataType) {
        Task { @MainActor in
            switch messagingDataType {
            case .chats:
                return
            case .messagesAdded(let messages, let chatId, let userId):
                await addMessagesFromUpdatedData(messages, chatId: chatId, userId: userId)
            case .messageUpdated(let updatedMessage, let newMessage):
                await updateMessageFromUpdatedData(updatedMessage, with: newMessage)
            case .messagesRemoved(let messages, let chatId):
                if case .existingChat(let chat) = conversationState,
                   chatId == chat.id {
                    let removedIds = messages.map { $0.id }
                    self.messages = self.messages.filter({ !removedIds.contains($0.id) })
                    for message in messages {
                        messagesCache.remove(message)
                    }
                }
            case .userInfoRefreshed(let user):
                if let i = listOfGroupParticipants.firstIndex(where: { $0.wallet == user.wallet }) {
                    listOfGroupParticipants[i] = user
                }
            case .channels, .channelFeedAdded, .refreshOfUserProfile, .messageReadStatusUpdated, .totalUnreadMessagesCountUpdated:
                return
            }
        }
    }
    
    private func addMessagesFromUpdatedData(_ messages: [MessagingChatMessageDisplayInfo], chatId: String, userId: String) async {
        if userId == self.profile.id,
           case .existingChat(let chat) = conversationState,
           chatId == chat.id,
           !messages.isEmpty {
            await self.addMessages(messages, scrollToBottom: true)
        }
    }
    
    private func updateMessageFromUpdatedData(_ updatedMessage: MessagingChatMessageDisplayInfo, with newMessage: MessagingChatMessageDisplayInfo) async {
        guard case .existingChat(let chat) = conversationState,
              updatedMessage.chatId == chat.id else { return }
        
        if let i = self.messages.firstIndex(where: { $0.id == updatedMessage.id }) {
            var newMessage = newMessage
            await newMessage.prepareToDisplay()
            self.messages[i] = newMessage
            messagesCache.remove(updatedMessage)
            messagesCache.insert(newMessage)
        }
        
        if case .reaction(let info) = updatedMessage.type {
            let currentReactions = messagesToReactions[info.messageId] ?? []
            let filteredReactions = currentReactions.filter({ $0.messageId != updatedMessage.id })
            messagesToReactions[info.messageId] = filteredReactions
        }
    }
}

// MARK: - UDFeatureFlagsListener
extension ChatViewModel: UDFeatureFlagsListener {
    func didUpdatedUDFeatureFlag(_ flag: UDFeatureFlag, withValue newValue: Bool) {
        switch flag {
        case .communityMediaEnabled:
            if isCommunityChat() {
                setIfUserCanSendAttachments()
                reloadCachedMessages()
            }
        }
    }
}

// MARK: - Open methods
extension ChatViewModel {
    struct ChatConstants {
        static let fetchLimit = 30
        static let loadMoreMessagesLimitSec: TimeInterval = 30
        static let minRequiredNumberOfVisibleMessagesOnLaunch = 20
    }
}

#Preview {
    NavigationViewWithCustomTitle(content: {
        ChatView(viewModel: .init(profile: .init(id: "",
                                                 wallet: "",
                                                 serviceIdentifier: .push),
                                  conversationState: MockEntitiesFabric.Messaging.existingChatConversationState(isGroup: true),
                                  router: HomeTabRouter(profile: .wallet(MockEntitiesFabric.Wallet.mockEntities().first!))))
        
    }, navigationStateProvider: { state in
    }, path: .constant(EmptyNavigationPath()))
}
