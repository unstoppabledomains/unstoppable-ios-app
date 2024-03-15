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
    
    init(fileName: String) {
        self.fileName = fileName
    }
    
    func retrieve() -> T? {
        nil
    }
    
    @discardableResult
    func store(_ data: T) -> Bool {
        
        return true
    }
    
    func remove() {
        
    }
}
