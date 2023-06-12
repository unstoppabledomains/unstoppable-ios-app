//
//  CoreDataService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import CoreData

class CoreDataService {
        
    private let persistentContainer: NSPersistentContainer
    
    var currentContext: NSManagedObjectContext { viewContext }
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    private(set) var backgroundContext: NSManagedObjectContext!
    
    init() {
        let dataModelName = "CoreDataModel"
        persistentContainer = NSPersistentContainer(name: dataModelName)
        loadStore()
    }
    
    func didLoadPersistentContainer() {
        Debugger.printInfo(topic: .CoreData, "Did load persistent container")
        let mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = mergePolicy
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = mergePolicy
    }
}

// MARK: - Open methods
extension CoreDataService {
    func saveContext() {
        Debugger.printInfo(topic: .CoreData, "Save context")
        if self.currentContext.hasChanges {
            do {
                try self.currentContext.save()
            } catch {
                Debugger.printFailure("An error occurred while saving context, error: \(error)", critical: true)
            }
        }
    }
    
    func resetContext() {
        currentContext.reset()
    }
    
    func createEntity<T: NSManagedObject>() throws -> T {
        guard let object = NSEntityDescription.insertNewObject(forEntityName: T.className, into: currentContext) as? T else { throw CoreDataError.failedToInsertObject }
        
        return object
    }
    
    func getEntities<T: NSManagedObject>(predicate: NSPredicate? = nil,
                                         sortDescriptions: [NSSortDescriptor]? = nil,
                                         fetchSize: Int? = nil,
                                         batchDescription: BatchDescription? = nil) throws -> [T] {
        let request = T.fetchRequest()
        request.includesPropertyValues = true
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortDescriptions
        if let batchDescription {
            request.fetchLimit = batchDescription.size
            request.fetchOffset = batchDescription.offset
        } else if let fetchSize {
            request.fetchLimit = fetchSize
            request.fetchOffset = 0
        }
        return try currentContext.fetch(request) as? [T] ?? []
    }
    
    func saveContext(if shouldSaveContext: Bool) {
        if shouldSaveContext {
            saveContext()
        }
    }
    
    func deleteObject(_ object: NSManagedObject, shouldSaveContext: Bool = true) {
        currentContext.delete(object)
        saveContext(if: shouldSaveContext)
    }
    
    func deleteObjects(_ objects: [NSManagedObject], shouldSaveContext: Bool = true) {
        objects.forEach { object in
            currentContext.delete(object)
        }
        saveContext(if: shouldSaveContext)
    }
}

// MARK: - Private methods
private extension CoreDataService {
    func loadStore() {
        persistentContainer.loadPersistentStores { [weak self]  description, error in
            if let error = error {
                if let url = description.url {
                    do {
                        try self?.persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: "sqlite")
                        self?.loadStore()
                    } catch { }
                }
                Debugger.printFailure("Unable to load persistent stores: \(error)", critical: true)
            } else {
                self?.didLoadPersistentContainer()
            }
        }
    }
}

// MARK: - Open methods
extension CoreDataService {
    struct BatchDescription {
        let size: Int
        let page: Int
        
        var offset: Int {
            (page - 1) * size
        }
    }
}

enum CoreDataError: Error {
    case failedToInsertObject
}
