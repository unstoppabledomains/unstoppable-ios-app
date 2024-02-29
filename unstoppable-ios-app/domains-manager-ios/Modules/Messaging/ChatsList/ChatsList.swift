//
//  ChatsList.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.07.2023.
//

import Foundation

// Namespace
enum ChatsList { }

extension ChatsList {
    enum PresentOptions {
        case `default`
        case showChatsList(profile: MessagingChatUserProfileDisplayInfo?)
        case showChat(options: PresentChatOptions, profile: MessagingChatUserProfileDisplayInfo)
        case showChannel(channelId: String, profile: MessagingChatUserProfileDisplayInfo)
        
        enum PresentChatOptions {
            case existingChat(chatId: String)
            case newChat(description: MessagingChatNewConversationDescription)
        }
    }
    
    enum SearchMode {
        case `default`
        case chatsOnly
        case channelsOnly
    }
    
    enum EditingModeAction {
        case edit, cancel, selectAll
    }
    
    enum DataType: String, Hashable, CaseIterable, UDSegmentedControlItem {
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
        
        var analyticButton: Analytics.Button { .messagingDataType }
    }
    
    struct DataTypeUIConfiguration: Hashable {
        let dataType: DataType
        let badge: Int
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
}

extension ChatsList {
    final class SearchManager {
        
        typealias SearchResult = ([MessagingChatUserDisplayInfo], [MessagingNewsChannel], [SearchDomainProfile])
        typealias SearchUsersTask = Task<SearchResult, Error>
        
        private let debounce: TimeInterval
        private var currentTask: SearchUsersTask?
        
        init(debounce: TimeInterval) {
            self.debounce = debounce
        }
        
        func search(with searchKey: String,
                    mode: ChatsList.SearchMode,
                    page: Int,
                    limit: Int,
                    for profile: MessagingChatUserProfileDisplayInfo) async throws -> SearchResult {
            // Cancel previous search task if it exists
            currentTask?.cancel()
            
            let debounce = self.debounce
            let task: SearchUsersTask = Task.detached {
                do {
                    await Task.sleep(seconds: debounce)
                    try Task.checkCancellation()
                    
                    async let searchUsersTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                        try await self.searchForUsers(with: searchKey,
                                                      mode: mode)
                    }, defaultValue: [])
                    async let searchChannelsTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                        try await self.searchForChannels(with: searchKey, mode: mode,
                                                         page: page, limit: limit,
                                                         for: profile)
                    }, defaultValue: [])
                    async let domainNamesTask = Utilities.catchingFailureAsyncTask(asyncCatching: {
                        try await self.searchForDomainNames(with: searchKey,
                                                            mode: mode)
                    }, defaultValue: [])
                    
                    
                    let (users, channels, domainNames) = await (searchUsersTask, searchChannelsTask, domainNamesTask)
                    
                    try Task.checkCancellation()
                    return (users, channels, domainNames)
                } catch NetworkLayerError.requestCancelled, is CancellationError {
                    return ([], [], [])
                } catch {
                    throw error
                }
            }
            
            currentTask = task
            let users = try await task.value
            return users
        }
        
        private func searchForUsers(with searchKey: String,
                                    mode: ChatsList.SearchMode) async throws -> [MessagingChatUserDisplayInfo] {
            switch mode {
            case .default, .chatsOnly:
                return try await appContext.messagingService.searchForUsersWith(searchKey: searchKey)
            case .channelsOnly:
                return []
            }
        }
        
        private func searchForChannels(with searchKey: String,
                                       mode: ChatsList.SearchMode,
                                       page: Int,
                                       limit: Int,
                                       for profile: MessagingChatUserProfileDisplayInfo) async throws -> [MessagingNewsChannel] {
            switch mode {
            case .default, .channelsOnly:
                return try await appContext.messagingService.searchForChannelsWith(page: page, limit: limit,
                                                                                   searchKey: searchKey, for: profile)
            case .chatsOnly:
                return []
            }
        }
        
        private func searchForDomainNames(with searchKey: String,
                                          mode: ChatsList.SearchMode) async throws -> [SearchDomainProfile] {
            switch mode {
            case .default, .chatsOnly:
                return try await NetworkService().searchForDomainsWith(name: searchKey, shouldBeSetAsRR: true)
            case .channelsOnly:
                return []
            }
        }
    }
}

@MainActor
protocol ChatsListCoordinator: AnyObject {
    func update(presentOptions: ChatsList.PresentOptions)
}

