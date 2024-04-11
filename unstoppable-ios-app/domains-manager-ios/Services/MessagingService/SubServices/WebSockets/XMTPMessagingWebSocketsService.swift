//
//  XMTPMessagingWebSocketsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import Foundation
import XMTPiOS

final class XMTPMessagingWebSocketsService {
    typealias ConversationStream = AsyncThrowingStream<Conversation, Error>
    typealias MessagesStream = AsyncThrowingStream<DecodedMessage, Error>
    
    private var listeningId: UUID?
}

// MARK: - MessagingWebSocketsServiceProtocol
extension XMTPMessagingWebSocketsService: MessagingWebSocketsServiceProtocol {
    func subscribeFor(profile: MessagingChatUserProfile, eventCallback: @escaping MessagingWebSocketEventCallback) throws {
        Task {
            do {
                let listeningId = UUID()
                self.listeningId = listeningId
                let profileId = profile.id
                let env = XMTPServiceHelper.getCurrentXMTPEnvironment()
                let client = try await XMTPServiceHelper.getClientFor(user: profile, env: env)
                
                listenForConversations(in: client, for: profileId, listeningId: listeningId, eventCallback: eventCallback)

                let conversations = try await client.conversations.list()
                for conversation in conversations {
                    listenForMessages(in: conversation,
                                      for: profileId,
                                      listeningId: listeningId,
                                      eventCallback: eventCallback)
                }
                
            } catch XMTPServiceHelper.XMTPHelperError.noClientKeys {
                return // No user
            } catch {
                try? subscribeFor(profile: profile, eventCallback: eventCallback)
            }
        }
    }
    
    func disconnectAll() {
        listeningId = nil
    }
}

// MARK: - Private methods
private extension XMTPMessagingWebSocketsService {
    func listenForConversations(in client: Client, 
                                for profileId: String,
                                listeningId: UUID,
                                eventCallback: @escaping MessagingWebSocketEventCallback) {
        guard listeningId == self.listeningId else { return }
        
        Task {
            do {
                for try await conversation in await client.conversations.stream() {
                    guard self.listeningId == listeningId else { break } /// There's no other way to stop listening at the moment
                    
                    Task.detached {
                        try? await XMTPPushNotificationsHelper.subscribeForTopics([conversation.topic], by: client)
                    }
                    
                    let webSocketChat = XMTPEntitiesTransformer.convertXMTPConversationToWebSocketChatEntity(conversation,
                                                                                                             userId: profileId)
                    eventCallback(.newChat(webSocketChat))
                    listenForMessages(in: conversation,
                                      for: profileId,
                                      listeningId: listeningId,
                                      eventCallback: eventCallback)
                }
            } catch {
                await Task.sleep(seconds: 3)
                listenForConversations(in: client, for: profileId, listeningId: listeningId, eventCallback: eventCallback)
            }
        }
    }
    
    func listenForMessages(in conversation: Conversation,
                           for profileId: String,
                           listeningId: UUID,
                           eventCallback: @escaping MessagingWebSocketEventCallback) {
        guard listeningId == self.listeningId else { return }
        Task {
            do {
                for try await message in conversation.streamMessages() {
                    guard self.listeningId == listeningId else { break } /// There's no other way to stop listening at the moment

                    let websocketMessage = XMTPEntitiesTransformer.convertXMTPMessageToWebSocketMessageEntity(message,
                                                                                                              peerAddress: conversation.peerAddress,
                                                                                                              userAddress: profileId)
                    eventCallback(.chatReceivedMessage(websocketMessage))
                }
            } catch {
                await Task.sleep(seconds: 3)
                listenForMessages(in: conversation, 
                                  for: profileId,
                                  listeningId: listeningId,
                                  eventCallback: eventCallback)
            }
        }
    }
}
