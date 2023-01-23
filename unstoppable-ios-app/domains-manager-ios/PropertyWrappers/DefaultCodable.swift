//
//  DefaultCodable.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.11.2022.
//

import Foundation

// MARK: - DefaultCodableStrategy
protocol DefaultCodableStrategy {
    associatedtype DefaultValue: Decodable
    
    /// The fallback value used when decoding fails
    static var defaultValue: DefaultValue { get }
}

// MARK: - DefaultCodable
@propertyWrapper
struct DefaultCodable<Default: DefaultCodableStrategy> {
    typealias DefaultType = Default
    var wrappedValue: Default.DefaultValue
    
    public init(wrappedValue: Default.DefaultValue) {
        self.wrappedValue = wrappedValue
    }
}

extension DefaultCodable: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = (try? container.decode(Default.DefaultValue.self)) ?? Default.defaultValue
    }
}

extension DefaultCodable: Encodable where Default.DefaultValue: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension DefaultCodable: Equatable where Default.DefaultValue: Equatable { }
extension DefaultCodable: Hashable where Default.DefaultValue: Hashable { }


// MARK: - Strategies
struct DefaultEmptyStringDecodingStrategy: DefaultCodableStrategy {
    static var defaultValue: String { "" }
}


extension KeyedDecodingContainer {
    /// Decodes successfully if key is available if not fallsback to the default value provided.
    func decode<P>(_: DefaultCodable<P>.Type, forKey key: Key) throws -> DefaultCodable<P> {
        if let value = try decodeIfPresent(DefaultCodable<P>.self, forKey: key) {
            return value
        } else {
            return DefaultCodable(wrappedValue: P.defaultValue)
        }
    }
}
