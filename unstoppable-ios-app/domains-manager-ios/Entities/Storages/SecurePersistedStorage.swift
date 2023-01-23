//
//  SecurePersistedStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 24.11.2022.
//

import Foundation
protocol SecurePersistedStorageProtocol {
    var workerQueue: DispatchQueue { get }
    var storageFileKey: String { get }
}

class SecurePersistedStorage<T: Codable>: SecurePersistedStorageProtocol {
    init(queueLabel: String,
         storageFileKey: String) {
        self.workerQueue = DispatchQueue(label: queueLabel)
        self.storageFileKey = storageFileKey
    }
    
    struct File: Codable {
        let schemaVersion: Int
        private var data: [T]
        
        static func createEmpty(schema: Int) -> File {
            File(schemaVersion: schema,
                 data: [])
        }
        
        func getEntries() -> [T] {
            data
        }
        
        mutating func append(entry: T) throws {
            data.append(entry)
        }
    }
    
    let storage: PrivateKeyStorage = iCloudPrivateKeyStorage()
    
    var workerQueue: DispatchQueue
    var storageFileKey: String
    var currentSchemaVersion = 1
        
    static func isICloudAvailable() -> Bool {
        #if DEBUG
        if TestsEnvironment.isTestModeOn {
            return TestsEnvironment.isICloudAvailableToUse
        }
        #endif
        return FileManager.default.ubiquityIdentityToken != nil
    }
            
    func appendToStorage(elements: [T]) throws {
        try workerQueue.sync {
            var file = getStorageContents()
            try elements
                .forEach { try file.append(entry: $0) }
            saveStorageContents(file: file)
        }
    }
    
    func save(element: T) throws {
        try workerQueue.sync {
            var file = getStorageContents()
            try file.append(entry: element)
            saveStorageContents(file: file)
        }
    }

    func getElements() -> [T] {
        return getStorageContents()
            .getEntries()
    }
    
    func clear() {
        workerQueue.sync {
            let file = File.createEmpty(schema: currentSchemaVersion)
            saveStorageContents(file: file)
        }
    }
    
    private func getStorageContents() -> File {
        guard let file = storage.retrieveValue(for: storageFileKey, isCritical: false) else {
            return File.createEmpty(schema: currentSchemaVersion)
        }
        
        guard let data = file.data(using: .utf8),
              let fileContents = try? JSONDecoder().decode(File.self, from: data) else {
            Debugger.printWarning("Found no backup file in iCloud")
            return File.createEmpty(schema: currentSchemaVersion) }
        
        guard fileContents.schemaVersion == currentSchemaVersion else {
            Debugger.printFailure("Current schema version is older than \(fileContents.schemaVersion)", critical: true)
            return File.createEmpty(schema: currentSchemaVersion)
        }
        return fileContents
    }
    
    private func saveStorageContents(file: File) {
        guard let dataString = file.jsonString() else {
            Debugger.printWarning("File failed to encode")
            return
        }
        storage.store(value: dataString, for: storageFileKey)
        return
    }
    
    func numberOfSavedElements() -> Int {
        getElements().count
    }
}
