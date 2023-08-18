//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import UserNotifications
import UIKit
import Intents

final class NotificationService: UNNotificationServiceExtension {

    private let fileManager = FileManager.default
    typealias NotificationContentCallback = (UNNotificationContent?)->()
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent,
           let event = ExternalEvent(pushNotificationPayload: bestAttemptContent.userInfo) {
            
            set(notificationContent: bestAttemptContent, for: event, completion: { content in
                if let content {
                    (content as? UNMutableNotificationContent)?.sound = .default
                    contentHandler(content)
                } else {
                    contentHandler(bestAttemptContent)
//                    contentHandler(UNNotificationContent()) // TODO: - Ignore notification. Enable when filtering entitlement is added to the project
                }
            })
        } else if let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

// MARK: - Handle notifications
private extension NotificationService {
    func set(notificationContent: UNMutableNotificationContent,
             for type: ExternalEvent,
             completion: @escaping NotificationContentCallback) {
        switch type {
        case .recordsUpdated(let domainName):
            setRecordsUpdatedContent(in: notificationContent, domainName: domainName, completion: completion)
        case .mintingFinished(let domainNames):
            guard let domainName = domainNames.last else {
                notificationContent.title = "NO DOMAIN"
                return }
            setMintingFinishedContent(in: notificationContent, domainName: domainName, completion: completion)
        case .domainTransferred(let domainName):
            setDomainTransferredContent(in: notificationContent, domainName: domainName, completion: completion)
        case .reverseResolutionSet(let domainName, let wallet):
            setReverseResolutionSetContent(in: notificationContent, domainName: domainName, wallet: wallet, completion: completion)
        case .reverseResolutionRemoved(let domainName, let wallet):
            setReverseResolutionRemovedContent(in: notificationContent, domainName: domainName, wallet: wallet, completion: completion)
        case .walletConnectRequest(let dAppName, let domainName):
            setWalletConnectRequestContent(in: notificationContent, dAppName: dAppName, domainName: domainName, completion: completion)
        case .wcDeepLink, .parkingStatusLocal:
            return
        case .domainProfileUpdated(let domainName):
            setDomainProfileUpdatedContent(in: notificationContent, domainName: domainName, completion: completion)
        case .domainFollowerAdded(let domainName, let domainFollower):
            setDomainFollowerAddedContent(in: notificationContent, domainName: domainName, domainFollower: domainFollower, completion: completion)
        case .badgeAdded(let domainName, let count):
            setBadgeAddedContent(in: notificationContent, domainName: domainName, count: count, completion: completion)
        case .chatMessage(let data):
            setChatMessageContent(in: notificationContent, data: data, completion: completion)
        case .chatChannelMessage(let data):
            setChatChannelMessageContent(in: notificationContent, data: data, completion: completion)
        case .chatXMTPMessage(let data):
            setChatXMTPMessageContent(in: notificationContent, data: data, completion: completion)
        case .chatXMTPInvite(let data):
            setChatXMTPInviteContent(in: notificationContent, data: data, completion: completion)
        }
    }
    
    func setRecordsUpdatedContent(in notificationContent: UNMutableNotificationContent,
                                  domainName: String,
                                  completion: @escaping NotificationContentCallback) {
        notificationContent.title = domainName
        notificationContent.body = String.Constants.recordsUpdated.localized()
        
        if let changes = AppGroupsBridgeService.shared.getDomainChanges().first(where: { $0.domainName == domainName }) {
            if let body = recordsUpdatedBody(for: changes) {
                notificationContent.body = body
            }
            AppGroupsBridgeService.shared.remove(domainRecordChanges: changes)
        }
        notificationContent.threadIdentifier = domainName + "records_updated"
        loadDomainAvatarFor(domainName: domainName,
                            in: notificationContent,
                            completion: completion)
    }
  
    func setMintingFinishedContent(in notificationContent: UNMutableNotificationContent,
                                   domainName: String,
                                   completion: @escaping NotificationContentCallback) {
        notificationContent.title = ""
        notificationContent.body = String.Constants.mintingFinished.localized(domainName)
        let mintedDomainsIdentifier = "minted_domains_group"
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            var domainNames = [domainName]
            if let notification = notifications.first(where: { $0.request.content.threadIdentifier == mintedDomainsIdentifier }) {
                let currentDomainNames = (notification.request.content.userInfo[ExternalEvent.Constants.DomainNamesNotificationKey] as? [String]) ?? []
                domainNames.append(contentsOf: currentDomainNames)
                notificationContent.body = String.Constants.mintingNFinished.localized(domainNames.count)
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.request.identifier])
            }
            notificationContent.userInfo[ExternalEvent.Constants.DomainNamesNotificationKey] = domainNames
            notificationContent.threadIdentifier = mintedDomainsIdentifier
            
            /// If completion to show new notification get called immediately, notification won't be removed by .removeDeliveredNotifications.
            /// Seems some issue in how UNUserNotificationCenter handle concurrent operations.
            /// Unfortunately there's no callback from removeDeliveredNotifications function and we have to rely on 'magic' number of delay before showing new notification.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion(nil)
            }
        }
    }

    func setDomainTransferredContent(in notificationContent: UNMutableNotificationContent,
                                     domainName: String,
                                     completion: @escaping NotificationContentCallback) {
        notificationContent.title = String.Constants.domainTransferredTitle.localized()
        notificationContent.body = String.Constants.domainTransferred.localized(domainName)
        completion(nil)
    }
    
    func setReverseResolutionSetContent(in notificationContent: UNMutableNotificationContent,
                                        domainName: String,
                                        wallet: String,
                                        completion: @escaping NotificationContentCallback) {
        notificationContent.title = ""
        notificationContent.body = String.Constants.reverseResolutionSet.localized(wallet.walletAddressTruncated, domainName)
        loadDomainAvatarFor(domainName: domainName,
                            in: notificationContent,
                            completion: completion)
    }
    
    func setReverseResolutionRemovedContent(in notificationContent: UNMutableNotificationContent,
                                            domainName: String,
                                            wallet: String,
                                            completion: @escaping NotificationContentCallback) {
        notificationContent.title = ""
        notificationContent.body = String.Constants.reverseResolutionRemoved.localized(wallet.walletAddressTruncated, domainName)
        loadDomainAvatarFor(domainName: domainName,
                            in: notificationContent,
                            completion: completion)
    }
    
    func setWalletConnectRequestContent(in notificationContent: UNMutableNotificationContent,
                                        dAppName: String,
                                        domainName: String?,
                                        completion: @escaping NotificationContentCallback) {
        notificationContent.title = domainName ?? ""
        notificationContent.body = String.Constants.walletConnectRequest.localized(dAppName)
        
        if let domainName {
            loadDomainAvatarFor(domainName: domainName,
                                in: notificationContent,
                                completion: completion)
        } else {
            completion(nil)
        }
    }
    
    func setDomainProfileUpdatedContent(in notificationContent: UNMutableNotificationContent,
                                        domainName: String,
                                        completion: @escaping NotificationContentCallback) {
        notificationContent.title = domainName
        notificationContent.body = String.Constants.domainProfileUpdated.localized()
        loadDomainAvatarFor(domainName: domainName,
                            in: notificationContent,
                            completion: completion)
    }
    
    func setDomainFollowerAddedContent(in notificationContent: UNMutableNotificationContent,
                                        domainName: String,
                                        domainFollower: String,
                                        completion: @escaping NotificationContentCallback) {
        notificationContent.title = domainName
        notificationContent.body = String.Constants.domainFollowerAdded.localized(domainFollower)
        loadDomainAvatarFor(domainName: domainName,
                            in: notificationContent,
                            completion: completion)
    }
    
    func setBadgeAddedContent(in notificationContent: UNMutableNotificationContent,
                              domainName: String,
                              count: Int,
                              completion: @escaping NotificationContentCallback) {
        notificationContent.title = domainName
        notificationContent.body = count > 1 ? String.Constants.badgesAdded.localized(count) : String.Constants.badgeAdded.localized()
        loadDomainAvatarFor(domainName: domainName,
                            in: notificationContent,
                            completion: completion)
    }
    
    func setChatMessageContent(in notificationContent: UNMutableNotificationContent,
                               data: ExternalEvent.ChatMessageEventData,
                               completion: @escaping NotificationContentCallback) {
        notificationContent.title = data.fromDomain ?? data.fromAddress.walletAddressTruncated
        switch data.requestType {
        case .message:
            notificationContent.body = String.Constants.newChatMessage.localized()
        case .request:
            notificationContent.body = String.Constants.newChatRequest.localized()            
        }
        
        if let domainName = data.fromDomain {
            loadDomainAvatarFor(domainName: domainName,
                                in: notificationContent,
                                completion: completion)
        } else {
            completion(nil)
        }
    }
    
    func setChatChannelMessageContent(in notificationContent: UNMutableNotificationContent,
                                      data: ExternalEvent.ChannelMessageEventData,
                                      completion: @escaping NotificationContentCallback) {
        notificationContent.title = data.channelName
        
        if let url = URL(string: data.channelIcon) {
            loadAvatarFor(source: .url(url),
                          name: data.channelName,
                          in: notificationContent,
                          completion: completion)
        } else {
            completion(nil)
        }
    }
    
    func setChatXMTPMessageContent(in notificationContent: UNMutableNotificationContent,
                                   data: ExternalEvent.ChatXMTPMessageEventData,
                                   completion: @escaping NotificationContentCallback) {
        Task {
            guard let notificationDisplayInfo = await XMTPPushNotificationsExtensionHelper.parseNotificationMessageFrom(data: data) else {
                completion(nil)
                return
            }
            notificationContent.title = notificationDisplayInfo.walletAddress.walletAddressTruncated
            notificationContent.body = notificationDisplayInfo.localizedMessage
            
            let senderWalletAddress = notificationDisplayInfo.walletAddress
            if senderWalletAddress != data.toAddress,
               let rrInfo = try? await loadRRInfoFor(address: senderWalletAddress),
               let url = rrInfo.pfpURLToUse {
                loadAvatarFor(source: .url(url),
                              name: rrInfo.name,
                              in: notificationContent,
                              completion: completion)
            } else {
                completion(notificationContent)
            }
        }
    }
    
    func setChatXMTPInviteContent(in notificationContent: UNMutableNotificationContent,
                                  data: ExternalEvent.ChatXMTPInviteEventData,
                                  completion: @escaping NotificationContentCallback) {
        notificationContent.title = data.toDomainName
        notificationContent.body = String.Constants.newChatRequest.localized()
        loadDomainAvatarFor(domainName: data.toDomainName,
                            in: notificationContent,
                            completion: completion)
    }
}

// MARK: - Private methods
private extension NotificationService {
    func recordsUpdatedBody(for changes: DomainRecordChanges) -> String? {
        guard !changes.changes.isEmpty else { return nil }
        
        let changesCount = changes.changes.count
        if changesCount == 1 {
            let change = changes.changes[0]
            switch change {
            case .added(let ticker):
                return String.Constants.recordsUpdatedSingleAdded.localized(ticker)
            case .removed(let ticker):
                return String.Constants.recordsUpdatedSingleRemoved.localized(ticker)
            case .updated(let ticker):
                return String.Constants.recordsUpdatedSingleUpdated.localized(ticker)
            }
        } else {
            if changes.changes.filter({ change in
                if case .added = change { return true }
                
                return false
            }).count == changesCount {
                return String.Constants.recordsUpdatedMultipleAdded.localized(changesCount)
            } else if changes.changes.filter({ change in
                if case .removed = change { return true }
                
                return false
            }).count == changesCount {
                return String.Constants.recordsUpdatedMultipleRemoved.localized(changesCount)
            }
            return String.Constants.recordsUpdatedMultipleUpdated.localized(changesCount)
        }
    }

    func loadRRInfoFor(address: String) async throws -> GlobalRR? {
        do {
            let url = buildRRInfoURLFor(address: address)
            let urlRequest = URLRequest(url: url)
            let (data, response) = try await makeURLRequest(urlRequest)

            if response.statusCode == 404 {
                return nil // 404 means no RR domain or ENS domain
            }
            let rrInfo = try JSONDecoder().decode(GlobalRR.self, from: data)
            return rrInfo
        } catch {
            throw error
        }
    }
    
    func buildRRInfoURLFor(address: String) -> URL {
        URL(string: "\(NetworkConfig.baseProfileAPIUrl)/profile/resolve/\(address)")!
    }
    
    func makeURLRequest(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            makeURLRequest(urlRequest) { result in
                switch result {
                case .success(let tuple):
                    continuation.resume(with: .success(tuple))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func makeURLRequest(_ urlRequest: URLRequest, completion: @escaping ((Result<(Data, HTTPURLResponse), Error>)->())) {
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let data,
               let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else if let error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "notification.extension", code: 1)))
            }
        }
        task.resume()
    }
    
    func loadDomainAvatarFor(domainName: String,
                             in notificationContent: UNMutableNotificationContent,
                             completion: @escaping NotificationContentCallback) {
        loadAvatarFor(source: .domain(domainName), name: domainName, in: notificationContent, completion: completion)
    }
    
    func loadAvatarFor(source: NotificationImageLoadingService.ImageSource,
                       name: String,
                       in notificationContent: UNMutableNotificationContent,
                       completion: @escaping NotificationContentCallback) {
        if #available(iOSApplicationExtension 15.0, *) {
            NotificationImageLoadingService.shared.imageFor(source: source) { image in
                if let image,
                   let imageData = image.jpegData(compressionQuality: 1) {
                    
                    let intent = self.intentFor(domainName: name,
                                                imageData: imageData)
                    
                    if let updatedContent = try? notificationContent.updating(from: intent) {
                        completion(updatedContent)
                        return
                    }
                }
                completion(nil)
            }
        } else {
            completion(nil)
        }
    }
    
    @available(iOSApplicationExtension 15.0, *)
    func intentFor(domainName: String, imageData: Data) -> INSendMessageIntent {
        let handle = INPersonHandle(value: domainName, type: .unknown)
        let avatar = INImage(imageData: imageData)
        let sender = INPerson(personHandle: handle,
                              nameComponents: nil,
                              displayName: domainName,
                              image: avatar,
                              contactIdentifier: nil,
                              customIdentifier: nil)
        
        let intent = INSendMessageIntent(recipients: nil,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: "",
                                         speakableGroupName: nil,
                                         conversationIdentifier: domainName,
                                         serviceName: "Domain",
                                         sender: sender,
                                         attachments: nil)
        //                        intent.setImage(avatar, forParameterNamed: \.sender)

        return intent
    }
    
    struct NetworkConfig {
        static var baseProfileAPIUrl: String {
            return "https://api.unstoppabledomains.com"
        }
    }
}
