//
//  MessagingUnreadCountingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2023.
//

import Foundation
import CoreData

final class CoreDataMessagingUnreadCountingService: NSObject {
    
    private var messagesFetchedResultsController: NSFetchedResultsController<CoreDataMessagingChatMessage>!
    private var feedFetchedResultsController: NSFetchedResultsController<CoreDataMessagingNewsChannelFeed>!
    private var stateHolder = StateHolder()
    private let serialQueue = DispatchQueue(label: "com.unstoppable.MessagingUnreadCountingService")
    private let context: NSManagedObjectContext
    var totalUnreadMessagesCountUpdated: ((Bool)->())?
    
    init(storageService: CoreDataMessagingStorageService) {
        context = storageService.backgroundContext
        super.init()
        
        initializeFetchedResultsControllers()
    }
}

// MARK: - MessagingUnreadCountingService
extension CoreDataMessagingUnreadCountingService: MessagingUnreadCountingServiceProtocol {
    func getTotalNumberOfUnreadMessages() -> Int {
        serialQueue.sync { totalUnreadEntitiesCount }
    }
    
    func getNumberOfUnreadMessagesIn(chatId: String, userId: String) -> Int {
        serialQueue.sync { unreadMessages.filter({ $0.chatId == chatId && $0.userId == userId }).count }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CoreDataMessagingUnreadCountingService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith diff: CollectionDifference<NSManagedObjectID>) {
        serialQueue.sync {
            let currentCounter = stateHolder.unreadMessagesCounter
            let newCounter = totalUnreadEntitiesCount
            Debugger.printInfo(topic: .Messaging, "CoreDataMessagingUnreadCountingService did receive update from fetch results controller. currentCounter = \(currentCounter). newCounter = \(newCounter)")
            if (currentCounter == 0 && newCounter != 0) {
                asyncNotifyHavingTotalUnreadMessagesCountChangedTo(havingUnreadMessages: true)
            } else if (newCounter == 0 && currentCounter != 0) {
                asyncNotifyHavingTotalUnreadMessagesCountChangedTo(havingUnreadMessages: false)
            }
            stateHolder.unreadMessagesCounter = newCounter
        }
    }
}

// MARK: - Private methods
private extension CoreDataMessagingUnreadCountingService {
    func initializeFetchedResultsControllers() {
        initializeMessagesFetchedResultsController()
        initializeFeedFetchedResultsController()
        
        stateHolder.unreadMessagesCounter = getTotalNumberOfUnreadMessages()
    }
    
    func initializeMessagesFetchedResultsController() {
        let request = CoreDataMessagingChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "isRead == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        messagesFetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                      managedObjectContext: context,
                                                                      sectionNameKeyPath: nil,
                                                                      cacheName: nil)
        do {
            try messagesFetchedResultsController.performFetch()
            messagesFetchedResultsController.delegate = self
        } catch {
            Debugger.printFailure("Failed to get unread messages", critical: true)
        }
    }
    
    func initializeFeedFetchedResultsController() {
        let request = CoreDataMessagingNewsChannelFeed.fetchRequest()
        request.predicate = NSPredicate(format: "isRead == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        feedFetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                      managedObjectContext: context,
                                                                      sectionNameKeyPath: nil,
                                                                      cacheName: nil)
        do {
            try feedFetchedResultsController.performFetch()
            feedFetchedResultsController.delegate = self
        } catch {
            Debugger.printFailure("Failed to get unread messages", critical: true)
        }
    }
    
    var unreadMessages: [CoreDataMessagingChatMessage] { messagesFetchedResultsController.fetchedObjects ?? [] }
    var unreadFeed: [CoreDataMessagingNewsChannelFeed] { feedFetchedResultsController.fetchedObjects ?? [] }
    var totalUnreadEntitiesCount: Int { unreadMessages.count + unreadFeed.count }
    
    func asyncNotifyHavingTotalUnreadMessagesCountChangedTo(havingUnreadMessages: Bool) {
        DispatchQueue.global().async {
            self.totalUnreadMessagesCountUpdated?(havingUnreadMessages)
        }
    }
    
    struct StateHolder {
        var unreadMessagesCounter: Int = 0
    }
}
