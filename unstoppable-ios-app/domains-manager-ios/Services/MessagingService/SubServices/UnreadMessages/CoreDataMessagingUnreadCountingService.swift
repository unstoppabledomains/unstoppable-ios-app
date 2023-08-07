//
//  MessagingUnreadCountingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.08.2023.
//

import Foundation
import CoreData

final class CoreDataMessagingUnreadCountingService: NSObject {
    
    private var fetchedResultsController: NSFetchedResultsController<CoreDataMessagingChatMessage>!
    private var stateHolder = StateHolder()
    private let serialQueue = DispatchQueue(label: "com.unstoppable.MessagingUnreadCountingService")
    private let context: NSManagedObjectContext
    var totalUnreadMessagesCountUpdated: ((Bool)->())?
    
    init(storageService: CoreDataMessagingStorageService) {
        context = storageService.viewContext
        super.init()
        
        initializeFetchedResultsController()
    }
}

// MARK: - MessagingUnreadCountingService
extension CoreDataMessagingUnreadCountingService: MessagingUnreadCountingServiceProtocol {
    func getTotalNumberOfUnreadMessages() -> Int {
        serialQueue.sync { unreadMessages.count }
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
            let newCounter = unreadMessages.count
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
    func initializeFetchedResultsController() {
        let request = CoreDataMessagingChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "isRead == NO")
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            fetchedResultsController.delegate = self
            stateHolder.unreadMessagesCounter = getTotalNumberOfUnreadMessages()
        } catch {
            Debugger.printFailure("Failed to get unread messages", critical: true)
        }
    }
    
    var unreadMessages: [CoreDataMessagingChatMessage] { fetchedResultsController.fetchedObjects ?? [] }
    
    func asyncNotifyHavingTotalUnreadMessagesCountChangedTo(havingUnreadMessages: Bool) {
        DispatchQueue.global().async {
            self.totalUnreadMessagesCountUpdated?(havingUnreadMessages)
        }
    }
    
    struct StateHolder {
        var unreadMessagesCounter: Int = 0
    }
}
