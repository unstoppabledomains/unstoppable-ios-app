//
//  Codable.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.04.2022.
//

import Foundation

extension Decodable {
    static func objectFromData(_ data: Data,
                               using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                               dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> Self? {
        genericObjectFromData(data, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
    }
    
    static func objectFromDataThrowing(_ data: Data,
                                       using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                       dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> Self {
        try genericObjectFromDataThrowing(data, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
    }
    
    static func objectsFromData(_ data: Data,
                                using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> [Self]? {
        genericObjectFromData(data, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
    }
    
    static func objectFromJSON(_ json: [String : Any],
                               using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                               dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> Self? {
        genericObjectFromJSON(json, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
    }
    
    static func objectsFromJSON(_ json: [[String : Any]],
                                using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> [Self]? {
        genericObjectFromJSON(json, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
    }
    
    static func genericObjectFromJSON<T: Decodable>(_ json: Any,
                                                    using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                    dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> T? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            return genericObjectFromData(jsonData, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
        } catch {
            Debugger.printFailure("Failed to parse \(self) with error \((error as NSError).userInfo)")
            return nil
        }
    }
    
    static func objectFromJSONString(_ jsonString: String,
                               using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                     dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
                                     encoding: String.Encoding = .utf8) -> Self? {
        genericObjectFromJSONString(jsonString, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy, encoding: encoding)
    }
    
    static func genericObjectFromJSONString<T: Decodable>(_ jsonString: String,
                                                    using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                          dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601,
                                                          encoding: String.Encoding = .utf8) -> T? {
        guard let jsonData = jsonString.data(using: encoding) else {
            Debugger.printFailure("Failed to parse jsonString to entity")
            return nil
        }
        return genericObjectFromData(jsonData, using: keyDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
    }
 
    static func genericObjectFromDataThrowing<T: Decodable>(_ data: Data,
                                                    using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                    dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        let object = try decoder.decode(T.self, from: data)
        return object
    }
    
    static func genericObjectFromData<T: Decodable>(_ data: Data,
                                                    using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                    dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> T? {
        do {
            return try genericObjectFromDataThrowing(data,
                                                     using: keyDecodingStrategy,
                                                     dateDecodingStrategy: dateDecodingStrategy)
        } catch {
            Debugger.printFailure("Failed to parse \(self) with error \((error as NSError).userInfo)")
            return nil
        }
    }
    
}

extension Encodable {
    func jsonDataThrowing(using keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                          dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.dateEncodingStrategy = dateEncodingStrategy
        
        return try encoder.encode(self)
    }
    
    func jsonData(using keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                  dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) -> Data? {
        try? jsonDataThrowing(using: keyEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
    }
  
    func jsonStringThrowing(using keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                    dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601,
                    encoding: String.Encoding = .utf8) throws -> String {
        guard let jsonString = jsonString(using: keyEncodingStrategy,
                                          dateEncodingStrategy: dateEncodingStrategy,
                                          encoding: encoding) else {
            throw CodableError.failedToCreateJSONString
        }
        return jsonString
    }
    
    func jsonString(using keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                    dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601,
                    encoding: String.Encoding = .utf8) -> String? {
        guard let jsonData = jsonData(using: keyEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy) else {
            return nil
        }
        return String(data: jsonData, encoding: encoding)
    }
    
    func jsonRepresentation(using keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                            dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) -> [String : Any]? {
        if let jsonData = jsonData(using: keyEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy),
           let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any] {
            
            return json
        }
        return nil
    }
}

protocol DateFormatterProtocol {
    func date(from string: String) -> Date?
}

extension DateFormatter: DateFormatterProtocol { }
extension ISO8601DateFormatter: DateFormatterProtocol { }

extension JSONDecoder.DateDecodingStrategy {
    static func defaultDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        .iso8601WithOptions([.withFractionalSeconds])
    }
    
    static func iso8601WithOptions(_ options: ISO8601DateFormatter.Options) -> JSONDecoder.DateDecodingStrategy {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(options)
        return dateStrategyUsing(formatters: [formatter])
    }
    
    private static func noTimeZoneIndicatorDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }
    
    static func noTimeZoneIndicatorDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        let formatter = noTimeZoneIndicatorDateFormatter()
        
        return dateStrategyUsing(formatters: [formatter])
    }
    
    static func nftDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
        let formatter = noTimeZoneIndicatorDateFormatter()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions.insert([.withFractionalSeconds])
        return dateStrategyUsing(formatters: [formatter, isoFormatter])
    }
    
    static func dateStrategyUsing(formatters: [DateFormatterProtocol]) -> JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
    }
}

enum CodableError: String, LocalizedError {
    case failedToCreateJSONString
    
    public var errorDescription: String? {
        return rawValue
    }
}

@propertyWrapper
struct DecodeIgnoringFailed<Value: Codable>: Codable {
    var wrappedValue: [Value] = []
    
    private struct _None: Decodable {}
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let decoded = try? container.decode(Value.self) {
                wrappedValue.append(decoded)
            }
            else {
                // item is silently ignored.
                _ = try? container.decode(_None.self)
            }
        }
    }
    
    init(value: [Value]) {
        self.wrappedValue = value
    }
}

@propertyWrapper
struct DecodeHashableIgnoringFailed<Value: Codable & Hashable>: Codable, Hashable {
    var wrappedValue: [Value] = []
    
    private struct _None: Decodable {}
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        while !container.isAtEnd {
            if let decoded = try? container.decode(Value.self) {
                wrappedValue.append(decoded)
            }
            else {
                // item is silently ignored.
                _ = try? container.decode(_None.self)
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wrappedValue)
    }
    
    init(value: [Value]) {
        self.wrappedValue = value
    }
    
    mutating func add(values: [Value]) {
        wrappedValue.append(contentsOf: values)
    }
}
