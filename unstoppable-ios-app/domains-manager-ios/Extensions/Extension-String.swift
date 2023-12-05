//
//  Extension-String.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.07.2021.
//

import Foundation

extension String {
   
    // REGEX validation patterns - MUST BE GLOBAL!!
    static let emailRegex = "[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}" + "\\@" + "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" + "(" + "\\." + "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" + ")+"
    static let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Self.emailRegex)

    func isValidEmail() -> Bool {
        return Self.emailPredicate.evaluate(with: self)
    }
    
    static func getDomainsWord(basedOn count: Int) -> String {
        return count == 1 ? "domain" : "domains"
    }
    
    var hasDecimalDigit: Bool {
        self.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    var hasLetters: Bool {
        !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: self))
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
    
    func isValidDomainName() -> Bool {
        guard let tld = self.getTldName() else { return false }
        return tld.isValidTld()
    }
    
    static let messagingAdditionalSupportedTLDs: Set = [GlobalConstants.lensDomainTLD,
                                                        GlobalConstants.coinbaseDomainTLD] // MARK: - Temporary urgent request

    func isValidDomainNameForMessagingSearch() -> Bool {
        guard let tld = self.getTldName() else { return false }
        
        let isMessagingTLD = Self.messagingAdditionalSupportedTLDs.contains(tld.lowercased())
        return tld.isValidTld() || isMessagingTLD
    }
    
    func isValidTld() -> Bool {
        let allTlds = User.instance.getAppVersionInfo().tlds
        return allTlds.contains(where: { $0.lowercased() == self.lowercased() } )
    }
    
    func isUDTLD() -> Bool {
        guard let tld = getTldName() else { return false }
        
        return tld.isValidTld() && tld != GlobalConstants.ensDomainTLD
    }
    
    func isValidAddress() -> Bool {
        let clean = self.droppedHexPrefix
        return clean.count == 40 && clean.isHexNumber
    }
    
    var isHexNumber: Bool {
        filter(\.isHexDigit).count == count
    }
  
    var convertedIntoReadableMessage: String {
        if self.droppedHexPrefix.isHexNumber {
            return String(data: Data(self.droppedHexPrefix.hexToBytes()), encoding: .utf8) ?? self
        } else {
            return self
        }
    }
}
