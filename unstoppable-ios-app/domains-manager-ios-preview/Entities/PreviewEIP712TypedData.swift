//
//  PreviewEIP712TypedData.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 24.05.2024.
//

import Foundation

public struct EIP712TypedData: Codable {
    public let domain: JSON
    public let message: JSON
}

public enum JSON: Equatable, Codable {
    case string(String)
    case number(Float)
    case object([String: JSON])
    case array([JSON])
    case bool(Bool)
    case null
}

public extension JSON {
    public var debugDescription: String { "" }

    subscript(index: Int) -> JSON? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }
    
    subscript(key: String) -> JSON? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }
}
