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
        persistentContainer = NSPersistentContainer(name: "CoreDataModel")
        persistentContainer.loadPersistentStores { [weak self]  description, error in
            if let error = error {
                Debugger.printFailure("Unable to load persistent stores: \(error)", critical: true)
            } else {
                self?.didLoadPersistentContainer()
            }
        }
    }
}

// MARK: - Open methods
extension CoreDataService {
    func saveContext() {
        Debugger.printInfo(topic: .CoreData, "Save context")
        if currentContext.hasChanges {
            do {
                try currentContext.save()
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
    
    func getEntities<T: NSManagedObject>() throws -> [T] {
        let request = T.fetchRequest()
        request.includesPropertyValues = true
        request.returnsObjectsAsFaults = false
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
    func didLoadPersistentContainer() {
        Debugger.printInfo(topic: .CoreData, "Did load persistent container")
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
    }
}

enum CoreDataError: Error {
    case failedToInsertObject
}
