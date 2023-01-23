//
//  Sequence.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.06.2022.
//

import Foundation

extension Sequence {
    func asyncThrowingMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var values = [T]()
        
        for element in self {
            await values.append(transform(element))
        }
        
        return values
    }
}
