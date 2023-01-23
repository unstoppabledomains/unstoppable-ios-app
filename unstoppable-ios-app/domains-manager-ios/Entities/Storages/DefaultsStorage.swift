//
//  DefaultsStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 19.07.2022.
//

import Foundation

class DefaultsStorage<T: Equatable> where T: Codable {
    enum Error: Swift.Error {
        case failedToFindElement
    }
    var storageKey: String = ""
    var q = DispatchQueue(label: "work-queue")

    func retrieveAll() -> [T] {
        guard let arrayObject = UserDefaults.standard
            .object(forKey: storageKey) as? Data else { return [] }
        guard let array = try? JSONDecoder().decode([T].self, from: arrayObject) else {
            Debugger.printFailure("Failed to decode connection intents from data: \(String(data: arrayObject, encoding: .utf8) ?? "n/a")", critical: false)
            return []
        }
        return array
    }
        
    func store(elements: [T]) throws {
        let appsData = try JSONEncoder().encode(elements)
        UserDefaults.standard.set(appsData, forKey: storageKey)
    }
    
    func save(newElement: T) {
        q.async {
            var elements = self.retrieveAll()
            elements.update(with: newElement)
            try? self.store(elements: elements)
        }
    }    
    
    final public func remove(when condition: @escaping (T) -> Bool) async -> T? {
        await withSafeCheckedContinuation { completion in
            q.async {
                var all = self.retrieveAll()
                guard let index = all.firstIndex(where: {condition($0)}) else {
                    completion(nil)
                    return
                }
                let removed = all.remove(at: index)
                try? self.store(elements: all)
                completion(removed)
            }
        }
    }
    
    final public func removeAll() {
        q.async {
            try? self.store(elements: [])
        }
    }
    
    final public func replace(with element: T,
                              when condition: @escaping (T) -> Bool) async -> T? {
        await withSafeCheckedContinuation { completion in
            q.async {
                var all = self.retrieveAll()
                guard let index = all.firstIndex(where: {condition($0)}) else {
                    completion(nil)
                    return
                }
                let replaced = all[index]
                all[index] = element
                try? self.store(elements: all)
                completion(replaced)
            }
        }
    }
}

extension Array where Element: Equatable {
    mutating func update(with newElement: Element) {
        update(newElement: newElement)
    }
}
