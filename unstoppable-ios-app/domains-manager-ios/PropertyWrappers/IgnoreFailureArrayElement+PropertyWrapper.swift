//
//  IgnoreFailureArrayElement+PropertyWrapper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.06.2022.
//

import Foundation

@propertyWrapper
struct IgnoreFailureArrayElement<Value: Codable>: Codable {
    var wrappedValue: [Value] = []
    
    private struct _None: Decodable {}
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let decoded = try? container.decode(Value.self) {
                wrappedValue.append(decoded)
            } else {
                _ = try? container.decode(_None.self)
            }
        }
    }
}
