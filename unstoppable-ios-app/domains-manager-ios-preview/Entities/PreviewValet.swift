//
//  PreviewValet.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct PreviewValet: ValetProtocol {
    func setObject(_ object: Data, forKey key: String) throws {
        
    }
    
    func object(forKey key: String) throws -> Data {
        Data()
    }
    
    func setString(_ privateKey: String, forKey: String) throws {
        
    }
    
    func string(forKey pubKeyHex: String) throws -> String {
        ""
    }
    
    func removeObject(forKey: String) throws {
        
    }
    
    
}
