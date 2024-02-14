//
//  PreviewChatViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.01.2024.
//

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    let profile = MessagingChatUserProfileDisplayInfo.mock(serviceIdentifier: .push)
    let channel = MessagingNewsChannel.mock()
    
    let vc = ChatViewController.nibInstance()
    let presenter = ChannelPreviewPresenter(view: vc,
                                            profile: profile,
                                            channel: channel)
    vc.presenter = presenter
    
    let nav = CNavigationController(rootViewController: vc)
    return nav
}

private final class ChannelPreviewPresenter: ChatViewPresenterProtocol {
 
    private weak var view: (any ChatViewProtocol)?
    private let profile: MessagingChatUserProfileDisplayInfo
    private let fetchLimit: Int = 20
    private var channel: MessagingNewsChannel
    
    init(view: any ChatViewProtocol,
         profile: MessagingChatUserProfileDisplayInfo,
         channel: MessagingNewsChannel) {
        self.view = view
        self.profile = profile
        self.channel = channel
    }
    var analyticsName: Analytics.ViewName { .channelFeed }
    
    func viewDidLoad() {
        view?.setUIState(.loading)
        Task {
            await Task.sleep(seconds: 1)
            showData()
            
            view?.setUIState(.chat)
        }
    }
    
    func didSelectItem(_ item: ChatViewController.Item) {
        
    }
    
    func willDisplayItem(_ item: ChatViewController.Item) {
        
    }
    
    func showData() {
        var snapshot = ChatSnapshot()

        let messages: [MessagingChatMessageDisplayInfo] = [createTextMessage(text: "hello"),
                                                           createImageMessage(image: UIImage.Preview.previewSquare)]
        let groupedMessages = [Date : [MessagingChatMessageDisplayInfo]].init(grouping: messages, by: { $0.time.dayStart })
        let sortedDates = groupedMessages.keys.sorted(by: { $0 < $1 })
        
        for date in sortedDates {
            let messages = groupedMessages[date] ?? []
            let title = MessageDateFormatter.formatMessagesSectionDate(date)
            snapshot.appendSections([.messages(title: title)])
            snapshot.appendItems(messages.map({ createSnapshotItemFrom(message: $0) }))
        }
        
        view?.applySnapshot(snapshot, animated: false, completion: { })
    }
    
    func createSnapshotItemFrom(message: MessagingChatMessageDisplayInfo) -> ChatViewController.Item {
        let isGroupChatMessage = true
        
        switch message.type {
        case .text(let textMessageDisplayInfo):
            return .textMessage(configuration: .init(message: message,
                                                     textMessageDisplayInfo: textMessageDisplayInfo,
                                                     isGroupChatMessage: isGroupChatMessage,
                                                     actionCallback: {  action in
                
            },
                                                     externalLinkHandleCallback: {  url in
              
            }))
        case .imageBase64(let imageMessageDisplayInfo):
            return .imageBase64Message(configuration: .init(message: message,
                                                            imageMessageDisplayInfo: imageMessageDisplayInfo,
                                                            isGroupChatMessage: isGroupChatMessage,
                                                            actionCallback: { action in
                
            }))
        case .imageData(let imageMessageDisplayInfo):
            return .imageDataMessage(configuration: .init(message: message,
                                                          imageMessageDisplayInfo: imageMessageDisplayInfo,
                                                          isGroupChatMessage: isGroupChatMessage,
                                                          actionCallback: { action in
                
            }))
        case .unknown:
            return .unsupportedMessage(configuration: .init(message: message,
                                                            isGroupChatMessage: isGroupChatMessage,
                                                            pressedCallback: {
             
            }))
        case .remoteContent:
            return .remoteContentMessage(configuration: .init(message: message,
                                                              isGroupChatMessage: isGroupChatMessage,
                                                              pressedCallback: {
                
            }))
        case .reaction(let info):
            return .textMessage(configuration: .init(message: message,
                                                     textMessageDisplayInfo: .init(text: info.content),
                                                     isGroupChatMessage: isGroupChatMessage,
                                                     actionCallback: {  action in
                
            },
                                                     externalLinkHandleCallback: {  url in
                
            }))
        }
    }
    
    func createTextMessage(text: String) -> MessagingChatMessageDisplayInfo {
        let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(domainName: "oleg.x", withPFP: true)
        let textDetails = MessagingChatMessageTextTypeDisplayInfo(text: text)
        
        return MessagingChatMessageDisplayInfo(id: "1",
                                        chatId: "2",
                                        userId: "1",
                                        senderType: .otherUser(user),
                                        time: Date(),
                                        type: .text(textDetails),
                                        isRead: false,
                                        isFirstInChat: true,
                                        deliveryState: .delivered,
                                        isEncrypted: false)
    }
    
    func createImageMessage(image: UIImage?) -> MessagingChatMessageDisplayInfo {
        let user = MockEntitiesFabric.Messaging.messagingChatUserDisplayInfo(domainName: "oleg.x", withPFP: true)
        
        var imageDetails = MessagingChatMessageImageBase64TypeDisplayInfo(base64: "")
        imageDetails.image = image
        return MessagingChatMessageDisplayInfo(id: "1",
                                               chatId: "2",
                                               userId: "1",
                                               senderType: .otherUser(user),
                                               time: Date(),
                                               type: .imageBase64(imageDetails),
                                               isRead: false,
                                               isFirstInChat: true,
                                               deliveryState: .delivered,
                                               isEncrypted: false)
        
        
    }
    
    
    
}
