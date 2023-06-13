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
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            Debugger.printInfo(topic: .CoreData, "Will Save context")
            do {
                try context.save()
            } catch {
                Debugger.printFailure("An error occurred while saving context, error: \(error)", critical: true)
            }
        }
    }
    
    func createEntity<T: NSManagedObject>(in context: NSManagedObjectContext) throws -> T {
        guard let object = NSEntityDescription.insertNewObject(forEntityName: T.className, into: context) as? T else { throw CoreDataError.failedToInsertObject }
        
        return object
    }
    
    func getEntities<T: NSManagedObject>(predicate: NSPredicate? = nil,
                                         sortDescriptions: [NSSortDescriptor]? = nil,
                                         fetchSize: Int? = nil,
                                         batchDescription: BatchDescription? = nil,
                                         from context: NSManagedObjectContext) throws -> [T] {
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
        return try context.fetch(request) as? [T] ?? []
    }
    
    func getEntitiesBlocking<T: NSManagedObject>(predicate: NSPredicate? = nil,
                                                 sortDescriptions: [NSSortDescriptor]? = nil,
                                                 fetchSize: Int? = nil,
                                                 batchDescription: BatchDescription? = nil,
                                                 from context: NSManagedObjectContext) throws -> [T] {
        var entities: [T]?
        context.performAndWait {
            entities = try? getEntities(predicate: predicate, sortDescriptions: sortDescriptions, fetchSize: fetchSize, batchDescription: batchDescription, from: context)
        }
        guard let entities else { throw CoreDataError.failedToFetchObjects }
        
        return entities
    }
    
    func countEntities<T: NSManagedObject>(_ type: T.Type,
                                           predicate: NSPredicate? = nil,
                                           in context: NSManagedObjectContext) throws -> Int {
        let request = T.fetchRequest()
        request.predicate = predicate
        return try context.count(for: request)
    }
    
    func countEntitiesBlocking<T: NSManagedObject>(_ type: T.Type,
                                                   predicate: NSPredicate? = nil,
                                                   in context: NSManagedObjectContext) throws -> Int {
        var count: Int?
        context.performAndWait {
            count = try? countEntities(type, predicate: predicate, in: context)
        }
        guard let count else { throw CoreDataError.failedToFetchObjects }
        
        return count
    }
    
    func saveContext(_ context: NSManagedObjectContext,
                     if shouldSaveContext: Bool) {
        if shouldSaveContext {
            saveContext(context)
        }
    }
    
    func deleteObject(_ object: NSManagedObject, from context: NSManagedObjectContext, shouldSaveContext: Bool = true) {
        context.delete(object)
        saveContext(context, if: shouldSaveContext)
    }
    
    func deleteObjects(_ objects: [NSManagedObject], from context: NSManagedObjectContext, shouldSaveContext: Bool = true) {
        objects.forEach { object in
            context.delete(object)
        }
        saveContext(context, if: shouldSaveContext)
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
    case failedToFetchObjects
    case failedToInsertObject
}
