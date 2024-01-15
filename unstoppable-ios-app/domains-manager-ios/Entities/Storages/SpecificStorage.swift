//
//  SpecificStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2022.
//

import Foundation

class SpecificStorage<T: Codable> {
    let fileName: String
    let directory: LocalStorage<T>.Directory
    
    private var storage = LocalStorage<T>()
    init(fileName: String, directory: LocalStorage<T>.Directory = .documents) {
        self.fileName = fileName
        self.directory = directory
    }
    
    func retrieve() -> T? {
        let result = storage.retrieve(self.fileName, from: directory, as: T.self)
        
        switch result {
        case .success(let array):
            return array
        case .failure(let error) :
            switch error {
            case .ReadFailed(let path):
                Debugger.printFailure("Reading local storage file at: \(path)", critical: false)
            case .FileNotFound: return nil
                
            case .DecodeFailed(let err):
                Debugger.printFailure("Decoding class \(String(describing: T.self)) from local storage file: \(err)", critical: false, suppressBugSnag: true)
            default: Debugger.printFailure("Reading file into class \(String(describing: T.self)) from local storage file: \(error)", critical: false)
            }
            return nil
        }
    }
    
    @discardableResult
    func store(_ data: T) -> Bool {
        if let error = storage.store(data, to: directory, to: fileName){
            Debugger.printFailure("Writing domains to local storage file failed: \(error.localizedDescription)", critical: true)
            return false
        }
        return true
    }
    
    func remove() {
        storage.remove(self.fileName, from: directory)
    }
}
