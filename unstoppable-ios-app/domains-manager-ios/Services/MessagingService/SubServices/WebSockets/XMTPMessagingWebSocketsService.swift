//
//  XMTPMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import Foundation
import XMTP

final class XMTPMessagingWebSocketsService {
    typealias ConversationStream = AsyncThrowingStream<Conversation, Error>
    typealias MessagesStream = AsyncThrowingStream<DecodedMessage, Error>
    
    private var listeningProfileId: String?
}

// MARK: - MessagingWebSocketsServiceProtocol
extension XMTPMessagingWebSocketsService: MessagingWebSocketsServiceProtocol {
    func subscribeFor(profile: MessagingChatUserProfile, eventCallback: @escaping MessagingWebSocketEventCallback) throws {
        Task {
            do {
                listeningProfileId = profile.id
                let profileId = profile.id
                let env = XMTPServiceHelper.getCurrentXMTPEnvironment()
                let client = try await XMTPServiceHelper.getClientFor(user: profile, env: env)
                
                listenForConversations(in: client, for: profileId, eventCallback: eventCallback)

                let conversations = try await client.conversations.list()
                for conversation in conversations {
                    listenForMessages(in: conversation, for: profileId, eventCallback: eventCallback)
                }
                
            } catch XMTPServiceHelper.XMTPHelperError.noClientKeys {
                return // No user
            } catch {
                try? subscribeFor(profile: profile, eventCallback: eventCallback)
            }
        }
    }
    
    func disconnectAll() {
        listeningProfileId = nil
    }
}

// MARK: - Private methods
private extension XMTPMessagingWebSocketsService {
    func listenForConversations(in client: Client, for profileId: String, eventCallback: @escaping MessagingWebSocketEventCallback) {
        guard profileId == listeningProfileId else { return }
        Task {
            do {
                for try await conversation in client.conversations.stream() {
                    guard profileId == listeningProfileId else { break } /// There's no other way to stop listening at the moment
                    
                    Task.detached {
                        try? await XMTPPushNotificationsHelper.subscribeForTopics([conversation.topic], by: client)
                    }
                    
                    let webSocketChat = XMTPEntitiesTransformer.convertXMTPConversationToWebSocketChatEntity(conversation,
                                                                                                             userId: profileId)
                    eventCallback(.newChat(webSocketChat))
                    listenForMessages(in: conversation,
                                      for: profileId,
                                      eventCallback: eventCallback)
                }
            } catch {
                try? await Task.sleep(seconds: 3)
                listenForConversations(in: client, for: profileId, eventCallback: eventCallback)
            }
        }
    }
    
    func listenForMessages(in conversation: Conversation, for profileId: String, eventCallback: @escaping MessagingWebSocketEventCallback) {
        guard profileId == listeningProfileId else { return }
        Task {
            do {
                for try await message in conversation.streamMessages() {
                    guard profileId == listeningProfileId else { break } /// There's no other way to stop listening at the moment

                    let websocketMessage = XMTPEntitiesTransformer.convertXMTPMessageToWebSocketMessageEntity(message,
                                                                                                              peerAddress: conversation.peerAddress,
                                                                                                              userAddress: profileId)
                    eventCallback(.chatReceivedMessage(websocketMessage))
                }
            } catch {
                try? await Task.sleep(seconds: 3)
                listenForMessages(in: conversation, for: profileId, eventCallback: eventCallback)
            }
        }
    }
}
