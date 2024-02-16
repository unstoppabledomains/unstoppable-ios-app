//
//  ChatViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

extension ChatView {
    
    @MainActor
    final class ChatViewModel: ObservableObject {
        
        private let profile: MessagingChatUserProfileDisplayInfo
        private let messagingService: MessagingServiceProtocol
        private let featureFlagsService: UDFeatureFlagsServiceProtocol
        private var conversationState: MessagingChatConversationState
        private let fetchLimit: Int = 20
        @Published private(set) var isLoadingMessages = false
        @Published private(set) var blockStatus: MessagingPrivateChatBlockingStatus = .unblocked
        @Published private(set) var isChannelEncrypted: Bool = true
        @Published private(set) var isAbleToContactUser: Bool = true
        @Published private(set) var messages: [MessagingChatMessageDisplayInfo] = []
        @Published private(set) var scrollToMessage: MessagingChatMessageDisplayInfo?
        @Published private(set) var messagesCache: Set<MessagingChatMessageDisplayInfo> = []
        @Published private(set) var isLoading = false
        @Published var input: String = ""
        @Published var error: Error?
        @Published private(set) var actions: [ChatViewController.NavButtonConfiguration.Action] = []

        private let serialQueue = DispatchQueue(label: "com.unstoppable.chat.view.serial")
        private var messagesToReactions: [String : Set<MessageReactionDescription>] = [:]
        
        init(profile: MessagingChatUserProfileDisplayInfo,
             conversationState: MessagingChatConversationState,
             messagingService: MessagingServiceProtocol = appContext.messagingService,
             featureFlagsService: UDFeatureFlagsServiceProtocol = appContext.udFeatureFlagsService) {
            self.profile = profile
            self.conversationState = conversationState
            self.messagingService = messagingService
            self.featureFlagsService = featureFlagsService
            
            
            messagingService.addListener(self)
            featureFlagsService.addListener(self)
//            view?.setUIState(.loading)
//            setupTitle()
            setupPlaceholder()
            setupFunctionality()
            loadAndShowData()
        }
        
        
        func sendPressed() {
//            let newMessage = Message(text: input,
//                                     isCurrentUser: [true, false].randomElement()!)
//            messages.append(newMessage)
//            scrollToMessage = newMessage
            input = ""
        }
        
        func additionalActionPressed(_ action: MessageInputView.AdditionalAction) {
            
        }
        
        private  func setupPlaceholder() {
            Task {
                let wallets = messagingService.fetchWalletsAvailableForMessaging()
                let userWallet = wallets.first(where: { $0.address.normalized == profile.wallet.normalized })
                let sender = userWallet?.rrDomain?.name ?? profile.wallet.walletAddressTruncated
                let placeholder = String.Constants.chatInputPlaceholderAsDomain.localized(sender)
                view?.setPlaceholder(placeholder)
            }
        }
        
        private func setupFunctionality() {
            if isCommunityChat() {
                let canSendAttachments = featureFlagsService.valueFor(flag: .communityMediaEnabled)
                view?.setCanSendAttachments(canSendAttachments)
            }
        }
        
        private func loadAndShowData() {
            Task {
                isLoading = true
                do {
                    switch conversationState {
                    case .existingChat(let chat):
                        isLoadingMessages = true
                        let cachedMessages = try await messagingService.getMessagesForChat(chat,
                                                                                           before: nil,
                                                                                           cachedOnly: true,
                                                                                           limit: fetchLimit)
                        await addMessages(cachedMessages)
                        showData(animated: false, scrollToBottomAnimated: false, isLoading: false)
                        
                        updateUIForChatApprovedStateAsync()
                        isChannelEncrypted = try await messagingService.isMessagesEncryptedIn(conversation: conversationState)
                        let updateMessages = try await messagingService.getMessagesForChat(chat,
                                                                                           before: nil,
                                                                                           cachedOnly: false,
                                                                                           limit: fetchLimit)
                        await addMessages(updateMessages)
                        showData(animated: true, isLoading: false)
                        isLoadingMessages = false
                        isLoading = false
                    case .newChat:
                        isChannelEncrypted = try await messagingService.isMessagesEncryptedIn(conversation: conversationState)
                        await updateUIForChatApprovedState()
                        isLoading = false
                        showData(animated: false, isLoading: false)
                    }
                } catch {
                    self.error = error
                    isLoading = false
                }
            }
        }
        
        private func loadMoreMessagesBefore(message: MessagingChatMessageDisplayInfo) {
            guard !isLoadingMessages,
                  case .existingChat(let chat) = conversationState else { return }
            
            isLoadingMessages = true
            showData(animated: false, isLoading: true)
            Task {
                do {
                    let unreadMessages = try await messagingService.getMessagesForChat(chat,
                                                                                       before: message,
                                                                                       cachedOnly: false,
                                                                                       limit: fetchLimit)
                    await addMessages(unreadMessages)
                    isLoadingMessages = false
                } catch {
                    self.error = error
                    isLoadingMessages = false
                }
                showData(animated: false, isLoading: false)
            }
        }
        
        private func reloadCachedMessages() {
            Task {
                if case .existingChat(let chat) = conversationState {
                    let cachedMessages = try await messagingService.getMessagesForChat(chat,
                                                                                       before: nil,
                                                                                       cachedOnly: true,
                                                                                       limit: fetchLimit)
                    await addMessages(cachedMessages)
                    showData(animated: false, isLoading: isLoadingMessages)
                }
            }
        }
        
        private func addMessages(_ messages: [MessagingChatMessageDisplayInfo]) async {
            messagesCache.formUnion(messages)
            
            let messages = serialQueue.sync {
                messages.filter { message in
                    if case .reaction(let info) = message.type {
                        let counter = MessageReactionDescription(content: info.content,
                                                                 messageId: message.id,
                                                                 referenceMessageId: info.messageId,
                                                                 isUserReaction: message.senderType.isThisUser)
                        _ = messagesToReactions[info.messageId, default: []].insert(counter)
                        return false
                    } else {
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
            self.messages.sort(by: { $0.time > $1.time })
        }
        
        private func loadRemoteContentOfMessageAsync(_ message: MessagingChatMessageDisplayInfo) {
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
        
       private func getCommunityChatDetails() -> MessagingCommunitiesChatDetails? {
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
        
        private func isCommunityChat() -> Bool {
            getCommunityChatDetails() != nil
        }
        
        private func setupBarButtons() async {
            var actions: [ChatViewController.NavButtonConfiguration.Action] = []
            
            func addCopyAddressActionFor(userInfo: MessagingChatUserDisplayInfo) {
                actions.append(.init(type: .copyAddress, callback: { [weak self] in
//                    self?.logButtonPressedAnalyticEvents(button: .copyWalletAddress)
                    CopyWalletAddressPullUpHandler.copyToClipboard(address: userInfo.wallet, ticker: BlockchainType.Ethereum.rawValue)
                }))
            }
            
            func addViewProfileActionIfPossibleFor(userInfo: MessagingChatUserDisplayInfo) async {
                if let domainName = userInfo.domainName {
                    let canViewProfile: Bool = domainName.isValidDomainName()
                    
                    if canViewProfile  {
                        actions.append(.init(type: .viewProfile, callback: { [weak self] in
//                            self?.logButtonPressedAnalyticEvents(button: .viewMessagingProfile)
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
//                                self?.logButtonPressedAnalyticEvents(button: .block)
                                self?.didPressBlockButton()
                            }))
                        case .bothBlocked, .otherUserIsBlocked:
                            Void()
                        }
                    }
                case .group(let groupDetails):
                    actions.append(.init(type: .viewInfo, callback: { [weak self] in
//                        self?.logButtonPressedAnalyticEvents(button: .viewGroupChatInfo)
                        self?.didPressViewGroupInfoButton(groupDetails: groupDetails)
                    }))
                    
                    if !groupDetails.isUserAdminWith(wallet: profile.wallet) {
                        actions.append(.init(type: .leave, callback: { [weak self] in
//                            self?.logButtonPressedAnalyticEvents(button: .leaveGroup)
                            self?.didPressLeaveButton()
                        }))
                    }
                case .community(let details):
                    actions.append(.init(type: .viewInfo, callback: { [weak self] in
//                        self?.logButtonPressedAnalyticEvents(button: .viewCommunityInfo,
//                                                             parameters: [.communityName: details.displayName])
                        self?.didPressViewCommunityInfoButton(communityDetails: details)
                    }))
                    
                    if !details.blockedUsersList.isEmpty {
                        actions.append(.init(type: .blockedUsers, callback: { [weak self] in
//                            self?.logButtonPressedAnalyticEvents(button: .viewBlockedUsersList,
//                                                                 parameters: [.communityName: details.displayName])
                            self?.didPressViewBlockedUsersListButton(communityDetails: details,
                                                                     in: chat)
                        }))
                    }
                    
                    if details.isJoined {
                        actions.append(.init(type: .leaveCommunity, callback: { [weak self] in
//                            self?.logButtonPressedAnalyticEvents(button: .leaveCommunity,
//                                                                 parameters: [.communityName: details.displayName])
                            self?.didPressLeaveCommunity(chat: chat)
                        }))
                    } else {
                        actions.append(.init(type: .joinCommunity, callback: { [weak self] in
//                            self?.logButtonPressedAnalyticEvents(button: .joinCommunity,
//                                                                 parameters: [.communityName: details.displayName])
                            self?.didPressJoinCommunity(chat: chat)
                        }))
                    }
                }
            }
            
            self.actions = actions
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
                    view?.cNavigationController?.popViewController(animated: true)
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        }
        
        func didPressViewDomainProfileButton(domainName: String,
                                             walletAddress: String) {
            Task {
                guard let view,
                      let wallet = appContext.walletsDataService.wallets.first(where: { $0.address == walletAddress.normalized }) else { return }
                UDRouter().showPublicDomainProfile(of: .init(walletAddress: walletAddress,
                                                             name: domainName),
                                                   by: wallet,
                                                   viewingDomain: nil,
                                                   preRequestedAction: nil,
                                                   in: view)
            }
        }
        
        func didPressViewGroupInfoButton(groupDetails: MessagingGroupChatDetails) {
            Task {
                guard let view else { return }
                
                await appContext.pullUpViewService.showGroupChatInfoPullUp(groupChatDetails: groupDetails,
                                                                           by: profile,
                                                                           in: view)
            }
        }
        
        func didPressViewCommunityInfoButton(communityDetails: MessagingCommunitiesChatDetails) {
            Task {
                guard let view else { return }
                
                await appContext.pullUpViewService.showCommunityChatInfoPullUp(communityDetails: communityDetails,
                                                                               by: profile,
                                                                               in: view)
            }
        }
        
        func didPressViewBlockedUsersListButton(communityDetails: MessagingCommunitiesChatDetails,
                                                in chat: MessagingChatDisplayInfo) {
            Task {
                guard let view else { return }
                
                await appContext.pullUpViewService.showCommunityBlockedUsersListPullUp(communityDetails: communityDetails,
                                                                                       by: profile,
                                                                                       unblockCallback: { [weak self] user in
                    Task {
                        view.setLoading(active: true)
                        if let chat = try? await self?.setGroupChatUser(user,
                                                                        blocked: false,
                                                                        chat: chat),
                           case .community(let communityDetails) = chat.type {
                            if communityDetails.blockedUsersList.isEmpty {
                                await view.dismissPullUpMenu()
                            } else {
                                self?.didPressViewBlockedUsersListButton(communityDetails: communityDetails, in: chat)
                            }
                        }
                        view.setLoading(active: false)
                    }
                },
                                                                                       in: view)
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
                    isLoading = true
                    try await messagingService.leaveGroupChat(chat)
                    view?.cNavigationController?.popViewController(animated: true)
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        }
        
        func setOtherUser(blocked: Bool) {
            guard case .existingChat(let chat) = conversationState else { return }
            
            Task {
                do {
                    isLoading = true
                    try await messagingService.setUser(in: .chat(chat), blocked: blocked)
                    await updateUIForChatApprovedState()
                } catch {
                    self.error = error
                }
                
                isLoading = false
            }
        }
        
        func handleChatMessageAction(_ action: ChatViewController.ChatMessageAction,
                                     forMessage message: MessagingChatMessageDisplayInfo) {
            guard case .existingChat(let chat) = conversationState else { return }
            
            switch action {
            case .resend:
//                logButtonPressedAnalyticEvents(button: .resendMessage)
                Task { try? await messagingService.resendMessage(message, in: chat) }
            case .delete:
//                logButtonPressedAnalyticEvents(button: .deleteMessage)
                Task { try? await messagingService.deleteMessage(message, in: chat) }
                if let i = messages.firstIndex(where: { $0.id == message.id }) {
                    messages.remove(at: i)
                    showData(animated: true, isLoading: isLoadingMessages)
                }
            case .unencrypted:
                guard let view else { return }
                
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
//                logButtonPressedAnalyticEvents(button: .copyChatMessageToClipboard)
                UIPasteboard.general.string = text
                Vibration.success.vibrate()
            case .saveImage(let image):
//                logButtonPressedAnalyticEvents(button: .saveChatImage)
                view?.saveImage(image)
            case .blockUserInGroup(let user):
//                logButtonPressedAnalyticEvents(button: .blockUserInGroupChat,
//                                               parameters: [.chatId : chat.id,
                                                            .wallet: user.wallet])
                Task {
                    isLoading = true
                    try? await setGroupChatUser(user,
                                                blocked: true,
                                                chat: chat)
                    isLoading = false
                }
            case .sendReaction(let content, let toMessage):
                sendReactionMesssage(content, toMessage: toMessage)
            }
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
                    self.view?.setUIState(.chat)
                    return
                }
                
                if let blockStatus = try? await messagingService.getBlockingStatusForChat(chat) {
                    self.blockStatus = blockStatus
                    switch blockStatus {
                    case .unblocked:
                        self.view?.setUIState(.chat)
                    case .currentUserIsBlocked:
                        self.view?.setUIState(.userIsBlocked)
                    case .otherUserIsBlocked, .bothBlocked:
                        self.view?.setUIState(.otherUserIsBlocked)
                    }
                }
            case .newChat(let newConversationDescription):
                func prepareToChat() {
                    view?.setUIState(.chat)
                    view?.startTyping()
                }
                
                if !messagingService.canContactWithoutProfileIn(newConversation: newConversationDescription) {
                    do {
                        let canContact = try await messagingService.isAbleToContactUserIn(newConversation: newConversationDescription,
                                                                                          by: profile)
                        if canContact {
                            prepareToChat()
                        } else {
                            isAbleToContactUser = false
                            self.view?.setUIState(.cantContactUser(ableToInvite: false))
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
        
        func shareContentOfMessage(_ message: MessagingChatMessageDisplayInfo) {
            Task {
                guard let contentURL = await messagingService.decryptedContentURLFor(message: message) else {
                    view?.showSimpleAlert(title: String.Constants.error.localized(),
                                          body: String.Constants.messagingShareDecryptionErrorMessage.localized())
                    Debugger.printFailure("Failed to decrypt message content of \(message.id) - \(message.time) in \(message.chatId)")
                    return
                }
                
                let activityViewController = UIActivityViewController(activityItems: [contentURL], applicationActivities: nil)
                activityViewController.completionWithItemsHandler = { _, completed, _, _ in
                    if completed {
                        AppReviewService.shared.appReviewEventDidOccurs(event: .didShareProfile)
                    }
                }
                view?.present(activityViewController, animated: true)
            }
        }
        
        func handleExternalLinkPressed(_ url: URL, in message: MessagingChatMessageDisplayInfo) {
            guard case .existingChat(let chat) = conversationState else { return }
            view.hideKeyboard()
            
            switch message.senderType {
            case .thisUser:
                openLinkOrDomainProfile(url)
            case .otherUser(let otherUser):
                Task {
                    do {
                        let action = try await appContext.pullUpViewService.showHandleChatLinkSelectionPullUp(in: view)
                        await view.dismissPullUpMenu()
                        
                        switch action {
                        case .handle:
                            openLinkOrDomainProfile(url)
                        case .block:
                            switch chat.type {
                            case .private:
                                try await messagingService.setUser(in: .chat(chat), blocked: true)
                            case .group, .community:
                                try await setGroupChatUser(otherUser, blocked: true, chat: chat)
                            }
                            
                            view.cNavigationController?.popViewController(animated: true)
                        }
                    } catch { }
                }
            }
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
                    await addMessages([])
                } else {
                    await addMessages(Array(messagesCache))
                }
                showData(animated: true, isLoading: false)
                await setupBarButtons()
                return chat
            case .private:
                return nil
            }
        }
        
        func openLinkOrDomainProfile(_ url: URL) {
            Task {
                let showDomainResult = await DomainProfileLinkValidator.getShowDomainProfileResultFor(url: url)
                
                switch showDomainResult {
                case .none:
                    view.openLink(.generic(url: url.absoluteString))
                case .showUserDomainProfile(let domain, let wallet, let action):
                    await UDRouter().showDomainProfileScreen(in: view,
                                                             domain: domain,
                                                             wallet: wallet,
                                                             preRequestedAction: action,
                                                             dismissCallback: nil)
                case .showPublicDomainProfile(let publicDomainDisplayInfo, let wallet, let action):
                    UDRouter().showPublicDomainProfile(of: publicDomainDisplayInfo,
                                                       by: wallet,
                                                       viewingDomain: nil,
                                                       preRequestedAction: action,
                                                       in: view)
                }
            }
        }
        
        
        
        
        // MARK: - Images related methods
            func didPickImageToSend(_ image: UIImage) {
                let resizedImage = image.resized(to: Constants.maxImageResolution) ?? image
                
                let confirmationVC = MessagingImageView.instantiate(mode: .confirmSending(callback: { [weak self] in
                    self?.sendImageMessage(resizedImage)
                }), image: resizedImage)
                view?.present(confirmationVC, animated: true)
            }
        
        // MARK: - Send message
            func sendTextMesssage(_ text: String) {
                let textTypeDetails = MessagingChatMessageTextTypeDisplayInfo(text: text)
                let messageType = MessagingChatMessageDisplayType.text(textTypeDetails)
                sendMessageOfType(messageType)
            }
            
            func sendReactionMesssage(_ content: String, toMessage: String) {
                let reactionTypeDetails = MessagingChatMessageReactionTypeDisplayInfo(content: content, messageId: toMessage)
                let messageType = MessagingChatMessageDisplayType.reaction(reactionTypeDetails)
                sendMessageOfType(messageType)
            }
            
            func sendImageMessage(_ image: UIImage) {
                guard let data = image.dataToUpload else { return }
                let imageTypeDetails = MessagingChatMessageImageDataTypeDisplayInfo(data: data, image: image)
                sendMessageOfType(.imageData(imageTypeDetails))
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
                            await addMessages([newMessage])
                            showData(animated: false, isLoading: isLoadingMessages)
                        } else {
                            await newMessage.prepareToDisplay()
                            messages.insert(newMessage, at: 0)
                            showData(animated: true, scrollToBottomAnimated: true, isLoading: isLoadingMessages)
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
}
