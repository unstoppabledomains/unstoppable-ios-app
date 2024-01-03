// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
import Foundation
import BigInt

/// A struct represents EIP712 type tuple
public struct EIP712Type: Codable {
    let name: String
    let type: String
}

/// A struct represents EIP712 Domain
public struct EIP712Domain: Codable {
    let name: String
    let version: String
    let chainId: Int
    let verifyingContract: String
}

/// A struct represents EIP712 TypedData
public struct EIP712TypedData: Codable {
    public let types: [String: [EIP712Type]]
    public let primaryType: String
    public let domain: JSON
    public let message: JSON
}

struct Crypto {
    static func hash(_ data: Data) -> Data {
        return data.sha3(.keccak256)
    }
}



extension EIP712TypedData {
    /// Type hash for the primaryType of an `EIP712TypedData`
    public var typeHash: Data {
        let data = encodeType(primaryType: primaryType)
        return Crypto.hash(data)
    }
    
    private func typeHash(_ type: String) -> Data {
        return Crypto.hash(encodeType(primaryType: type))
    }
    
    private func hashStruct(_ data: JSON, type: String) -> Data {
        return Crypto.hash(typeHash(type) + encodeData(data: data, type: type))
    }

    /// Sign-able hash for an `EIP712TypedData`
    public var signHash: Data {
        let data = Data([0x19, 0x01]) +
            Crypto.hash(encodeData(data: domain, type: "EIP712Domain")) +
            Crypto.hash(encodeData(data: message, type: primaryType))
        return Crypto.hash(data)
    }

    /// Recursively finds all the dependencies of a type
    func findDependencies(primaryType: String, dependencies: Set<String> = Set<String>()) -> Set<String> {
        var found = dependencies
        guard !found.contains(primaryType),
            let primaryTypes = types[primaryType] else {
                return found
        }
        found.insert(primaryType)
        for type in primaryTypes {
            findDependencies(primaryType: type.type, dependencies: found)
                .forEach { found.insert($0) }
        }
        return found
    }

    /// Encode a type of struct
    public func encodeType(primaryType: String) -> Data {
        var depSet = findDependencies(primaryType: primaryType)
        depSet.remove(primaryType)
        let sorted = [primaryType] + Array(depSet).sorted()
        let encoded = sorted.map { type in
            let param = types[type]!.map { "\($0.type) \($0.name)" }.joined(separator: ",")
            return "\(type)(\(param))"
        }.joined()
        return encoded.data(using: .utf8) ?? Data()
    }

    /// Encode an instance of struct
    ///
    /// Implemented with `ABIEncoder` and `ABIValue`
    public func encodeData(data: JSON, type: String) -> Data {
        let encoder = ABIEncoder()
        var values: [ABIValue] = []
        do {
            let typeHash = Crypto.hash(encodeType(primaryType: type))
            let typeHashValue = try ABIValue(typeHash, type: .bytes(32))
            values.append(typeHashValue)
            if let valueTypes = types[type] {
                try valueTypes.forEach { field in
                    if let _ = types[field.type],
                        let json = data[field.name] {
                        let nestEncoded = encodeData(data: json, type: field.type)
                        values.append(try ABIValue(Crypto.hash(nestEncoded), type: .bytes(32)))
                    } else if let value = makeABIValue(data: data[field.name], type: field.type) {
                        values.append(value)
                    }
                }
            }
            try encoder.encode(tuple: values)
        } catch let error {
            Debugger.printFailure(error.localizedDescription)
        }
        return encoder.data
    }

    /// Helper func for `encodeData`
    private func makeABIValue(data: JSON?, type: String) -> ABIValue? {
        if (type == "string" || type == "bytes"),
            let value = data?.stringValue,
            let valueData = value.data(using: .utf8) {
            return try? ABIValue(Crypto.hash(valueData), type: .bytes(32))
        } else if type == "bool",
            let value = data?.boolValue {
            return try? ABIValue(value, type: .bool)
        } else if type == "address",
            let value = data?.stringValue,
            let address = TrustAddress(string: value) {
            return try? ABIValue(address, type: .address)
        } else if type.starts(with: "uint") {
            let size = parseIntSize(type: type, prefix: "uint")
            guard size > 0 else { return nil }
            if let value = data?.floatValue {
                return try? ABIValue(Int(value), type: .uint(bits: size))
            } else if let value = data?.stringValue,
                let bigInt = BigUInt(value: value) {
                return try? ABIValue(bigInt, type: .uint(bits: size))
            }
        } else if type.starts(with: "int") {
            let size = parseIntSize(type: type, prefix: "int")
            guard size > 0 else { return nil }
            if let value = data?.floatValue {
                return try? ABIValue(Int(value), type: .int(bits: size))
            } else if let value = data?.stringValue,
                let bigInt = BigInt(value: value) {
                return try? ABIValue(bigInt, type: .int(bits: size))
            }
        } else if type.starts(with: "bytes") {
            if let length = Int(type.dropFirst("bytes".count)),
                let value = data?.stringValue {
                if value.starts(with: "0x"),
                    let hex = Data(hexString: value) {
                    return try? ABIValue(hex, type: .bytes(length))
                } else {
                    return try? ABIValue(Data(Array(value.utf8)), type: .bytes(length))
                }
            }
        }
        //TODO array types
        return nil
    }

    /// Helper func for encoding uint / int types
    private func parseIntSize(type: String, prefix: String) -> Int {
        guard type.starts(with: prefix),
            let size = Int(type.dropFirst(prefix.count)) else {
            return -1
        }

        if size < 8 || size > 256 || size % 8 != 0 {
            return -1
        }
        return size
    }
}

private extension BigInt {
    init?(value: String) {
        if value.starts(with: "0x") {
            self.init(String(value.dropFirst(2)), radix: 16)
        } else {
            self.init(value)
        }
    }
}

private extension BigUInt {
    init?(value: String) {
        if value.starts(with: "0x") {
            self.init(String(value.dropFirst(2)), radix: 16)
        } else {
            self.init(value)
        }
    }
}

/// A JSON value representation. This is a bit more useful than the naïve `[String:Any]` type
/// for JSON values, since it makes sure only valid JSON values are present & supports `Equatable`
/// and `Codable`, so that you can compare values for equality and code and decode them into data
/// or strings.
public enum JSON: Equatable {
    case string(String)
    case number(Float)
    case object([String: JSON])
    case array([JSON])
    case bool(Bool)
    case null
}

extension JSON: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let object = try? container.decode([String: JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Float.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool.description
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}

public extension JSON {
    /// Return the string value if this is a `.string`, otherwise `nil`
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    /// Return the float value if this is a `.number`, otherwise `nil`
    var floatValue: Float? {
        if case .number(let value) = self {
            return value
        }
        return nil
    }

    /// Return the bool value if this is a `.bool`, otherwise `nil`
    var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }

    /// Return the object value if this is an `.object`, otherwise `nil`
    var objectValue: [String: JSON]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }

    /// Return the array value if this is an `.array`, otherwise `nil`
    var arrayValue: [JSON]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }

    /// Return `true` if this is `.null`
    var isNull: Bool {
        if case .null = self {
            return true
        }
        return false
    }

    /// If this is an `.array`, return item at index
    ///
    /// If this is not an `.array` or the index is out of bounds, returns `nil`.
    subscript(index: Int) -> JSON? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    /// If this is an `.object`, return item at key
    subscript(key: String) -> JSON? {
        if case .object(let dict) = self {
            return dict[key]
        }
        return nil
    }
}

public protocol AddressProtocol: CustomStringConvertible {
    /// Validates that the raw data is a valid address.
    static func isValid(data: Data) -> Bool

    /// Validates that the string is a valid address.
    static func isValid(string: String) -> Bool

    /// Raw representation of the address.
    var data: Data { get }

    /// Creates a address from a string representation.
    init?(string: String)

    /// Creates a address from a raw representation.
    init?(data: Data)
}

public struct TrustAddress: AddressProtocol, Hashable {
    public static let size = 20

    /// Validates that the raw data is a valid address.
    static public func isValid(data: Data) -> Bool {
        return data.count == TrustAddress.size
    }

    /// Validates that the string is a valid address.
    static public func isValid(string: String) -> Bool {
        guard let data = Data(hexString: string) else {
            return false
        }
        return TrustAddress.isValid(data: data)
    }

    /// Raw address bytes, length 20.
    public let data: Data

    /// EIP55 representation of the address.
    public let eip55String: String

    /// Creates an address with `Data`.
    ///
    /// - Precondition: data contains exactly 20 bytes
    public init?(data: Data) {
        if !TrustAddress.isValid(data: data) {
            return nil
        }
        self.data = data
        eip55String = EthereumChecksum.computeString(for: data, type: .eip55)
    }

    /// Creates an address with an hexadecimal string representation.
    public init?(string: String) {
        guard let data = Data(hexString: string), TrustAddress.isValid(data: data) else {
            return nil
        }
        self.init(data: data)
    }

    public var description: String {
        return eip55String
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data.hashValue)
    }

    public static func == (lhs: TrustAddress, rhs: TrustAddress) -> Bool {
        return lhs.data == rhs.data
    }
}



public enum EthereumChecksumType {
    case eip55
    case wanchain
}

public struct EthereumChecksum {
    public static func computeString(for data: Data, type: EthereumChecksumType) -> String {
        let addressString = data.hexString
        let hashInput = addressString.data(using: .ascii)!
        let hash = Crypto.hash(hashInput).hexString

        var string = "0x"
        for (a, h) in zip(addressString, hash) {
            switch (a, h) {
            case ("0", _), ("1", _), ("2", _), ("3", _), ("4", _), ("5", _), ("6", _), ("7", _), ("8", _), ("9", _):
                string.append(a)
            case (_, "8"), (_, "9"), (_, "a"), (_, "b"), (_, "c"), (_, "d"), (_, "e"), (_, "f"):
                switch type {
                case .eip55:
                    string.append(contentsOf: String(a).uppercased())
                case .wanchain:
                    string.append(contentsOf: String(a).lowercased())
                }
            default:
                switch type {
                case .eip55:
                    string.append(contentsOf: String(a).lowercased())
                case .wanchain:
                    string.append(contentsOf: String(a).uppercased())
                }
            }
        }

        return string
    }
}

extension Data {
    /// Initializes `Data` with a hex string representation.
    public init?(hexString: String) {
        let string: String
        if hexString.hasPrefix("0x") {
            string = String(hexString.dropFirst(2))
        } else {
            string = hexString
        }

        // Check odd length hex string
        if string.count % 2 != 0 {
            return nil
        }

        // Check odd characters
        if string.contains(where: { !$0.isHexDigit }) {
            return nil
        }

        // Convert the string to bytes for better performance
        guard let stringData = string.data(using: .ascii, allowLossyConversion: true) else {
            return nil
        }

        self.init(capacity: string.count / 2)
        let stringBytes = Array(stringData)
        for i in stride(from: 0, to: stringBytes.count, by: 2) {
            guard let high = Data.value(of: stringBytes[i]) else {
                return nil
            }
            if i < stringBytes.count - 1, let low = Data.value(of: stringBytes[i + 1]) {
                append((high << 4) | low)
            } else {
                append(high)
            }
        }
    }
//
//    /// Converts an ASCII byte to a hex value.
    private static func value(of nibble: UInt8) -> UInt8? {
        guard let letter = String(bytes: [nibble], encoding: .ascii) else { return nil }
        return UInt8(letter, radix: 16)
    }

    /// Returns the hex string representation of the data.
    public var hexString: String {
        return map({ String(format: "%02x", $0) }).joined()
    }
}

extension BigUInt {

    //MARK: String Conversion

    /// Calculates the number of numerals in a given radix that fit inside a single `Word`.
    ///
    /// - Returns: (chars, power) where `chars` is highest that satisfy `radix^chars <= 2^Word.bitWidth`. `power` is zero
    ///   if radix is a power of two; otherwise `power == radix^chars`.
//    fileprivate static func charsPerWord(forRadix radix: Int) -> (chars: Int, power: Word) {
//        var power: Word = 1
//        var overflow = false
//        var count = 0
//        while !overflow {
//            let (p, o) = power.multipliedReportingOverflow(by: Word(radix))
//            overflow = o
//            if !o || p == 0 {
//                count += 1
//                power = p
//            }
//        }
//        return (count, power)
//    }

    /// Initialize a big integer from an ASCII representation in a given radix. Numerals above `9` are represented by
    /// letters from the English alphabet.
    ///
    /// - Requires: `radix > 1 && radix < 36`
    /// - Parameter `text`: A string consisting of characters corresponding to numerals in the given radix. (0-9, a-z, A-Z)
    /// - Parameter `radix`: The base of the number system to use, or 10 if unspecified.
    /// - Returns: The integer represented by `text`, or nil if `text` contains a character that does not represent a numeral in `radix`.
    public init?(_ text: String, radix: Int = 10) {
        // FIXME Remove this member when SE-0183 is done
        self.init(Substring(text), radix: radix)
    }
}
