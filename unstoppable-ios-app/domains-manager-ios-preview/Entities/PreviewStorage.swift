//
//  PreviewStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct Storage {
    
    private init() { }
    static var instance = Storage()
    func cleanAllCache() {
        
    }
}

class SpecificStorage<T: Codable> {
    let fileName: String
    private var data: T? = nil
    private let queue = DispatchQueue(label: "preview.serial.storage")
    
    init(fileName: String) {
        self.fileName = fileName
    }
    
    func retrieve() -> T? {
        queue.sync { data }
    }
    
    @discardableResult
    func store(_ data: T) -> Bool {
        queue.sync {
            self.data = data
            return true
        }
    }
    
    func remove() {
        queue.sync {
            self.data = nil
        }
    }
}
