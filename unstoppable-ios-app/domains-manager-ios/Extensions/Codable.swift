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
            Debugger.printInfo("Failed to parse \(self) with error \((error as NSError).userInfo)")
            return nil
        }
    }
    
    static func genericObjectFromData<T: Decodable>(_ data: Data,
                                                    using keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                                    dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601) -> T? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        let object = try? decoder.decode(T.self, from: data)
        return object
    }
    
}

extension Encodable {
    func jsonData(using keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
                  dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601) -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.dateEncodingStrategy = dateEncodingStrategy
        
        return try? encoder.encode(self)
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

extension JSONDecoder.DateDecodingStrategy {
    static func iso8601WithOptions(_ options: ISO8601DateFormatter.Options) -> JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions.insert(options)
            
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
    }
}
