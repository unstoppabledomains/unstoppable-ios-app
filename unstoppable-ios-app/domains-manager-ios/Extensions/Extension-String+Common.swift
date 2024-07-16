//
//  Extension-String+Common.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation

extension String {
    static var hexPrefix: String { "0x" }
    
    var hasHexPrefix: Bool {
        return self.hasPrefix(String.hexPrefix)
    }
    var normalized: String {
        let cleanAddress = self.droppedHexPrefix.lowercased()
        if cleanAddress.count == 64 {
            return String.hexPrefix + cleanAddress.dropFirst(24)
        }
        return String.hexPrefix + cleanAddress
    }
    
    var droppedHexPrefix: String {
        return self.hasHexPrefix ? String(self.dropFirst(String.hexPrefix.count)) : self
    }
    
    var hexRepresentation: String {
        var hex = self.utf8.map { String(format: "%02X", $0) }.joined()
        if !hex.hasHexPrefix {
            hex = String.hexPrefix + hex
        }
        return hex
    }
    
    var hasDecimalDigit: Bool {
        self.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var hasLetters: Bool {
        !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
    }
    
    func isValidAddress() -> Bool {
        let clean = self.droppedHexPrefix
        return clean.count == 40 && clean.isHexNumber
    }
    
    var isHexNumber: Bool {
        filter(\.isHexDigit).count == count
    }
    
    func isValidPassword() -> Bool {
        self.count > 7 && self.hasDecimalDigit
    }
    
    func isAlphanumeric() -> Bool {
        return self.replacingOccurrences(of: " ", with: "")
            .rangeOfCharacter(from: CharacterSet.letters.inverted) == nil
    }
    
    func isValidPrivateKey() -> Bool {
        self.droppedHexPrefix.count == 64 && self.droppedHexPrefix.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }
    
    func isValidSeedPhrase() -> Bool {
        return self.split(separator: " ").count == Seed.seedWordsCount && self.isAlphanumeric()
    }
    
    var trimmedSpaces: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

typealias DomainName = String

extension DomainName {
    private func domainComponents() -> [String]? {
        let components = self.components(separatedBy: String.dotSeparator)
        guard components.count >= 2 else {
            Debugger.printFailure("Domain name with no detectable NS: \(self)", critical: false)
            return nil
        }
        return components
    }
    
    func getTldName() -> String? {
        guard let tldName = domainComponents()?.last else {
            Debugger.printFailure("Couldn't get domain TLD name", critical: false)
            return nil
        }
        return tldName.lowercased()
    }
    
    func getBelowTld() -> String? {
        guard let domainName = getComponentsBelowTld()?.joined(separator: String.dotSeparator) else {
            Debugger.printFailure("Couldn't get domain name", critical: false)
            return nil
        }
        return domainName
    }
    
    func getComponentsBelowTld() -> [String]? {
        guard let components = domainComponents() else { return nil }
        return components.dropLast(1)
    }
    
    func isSubdomain() -> Bool {
        guard let components = domainComponents() else { return false }
        
        return components.count > 2
    }
}

enum Seed: CustomStringConvertible, Equatable {
    case encryptedPrivateKey (String)
    case encryptedSeedPhrase (String)
    
    var description: String {
        switch self {
        case .encryptedPrivateKey(let pk): return pk
        case .encryptedSeedPhrase(let phrase): return phrase
        }
    }
    
    static let seedWordsCount = 12
}
