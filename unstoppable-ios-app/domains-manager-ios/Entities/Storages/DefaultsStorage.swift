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
        
    func save(newElement: T) {
        q.async {
            var elements = self.getAllFromDefaults()
            elements.update(with: newElement)
            try? self.store(elements: elements)
        }
    }
    
    func substitute(element: T, at index: Int) {
        q.async {
            var all = self.getAllFromDefaults()
            all[index] = element
            try? self.store(elements: all)
        }
    }
    
    func retrieveAll() -> [T] {
        var result: [T] = []
        q.sync {
            result = getAllFromDefaults()
        }
        return result
    }
    
    final public func remove(when condition: @escaping (T) -> Bool) async -> T? {
        await withSafeCheckedContinuation { completion in
            q.async {
                var all = self.getAllFromDefaults()
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
                var all = self.getAllFromDefaults()
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
    
    // private methods
    private func store(elements: [T]) throws {
        let appsData = try JSONEncoder().encode(elements)
        UserDefaults.standard.set(appsData, forKey: storageKey)
    }
    
    private func getAllFromDefaults() -> [T] {
        guard let arrayObject = UserDefaults.standard
            .object(forKey: storageKey) as? Data else { return [] }
        guard let array = try? JSONDecoder().decode([T].self, from: arrayObject) else {
            return []
        }
        return array
    }
}

extension Array where Element: Equatable {
    mutating func update(with newElement: Element) {
        update(newElement: newElement)
    }
}
