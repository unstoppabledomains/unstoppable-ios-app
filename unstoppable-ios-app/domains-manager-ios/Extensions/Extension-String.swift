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
    
    var convertedIntoReadableMessage: String {
        if self.droppedHexPrefix.isHexNumber {
            return String(data: Data(self.droppedHexPrefix.hexToBytes()), encoding: .utf8) ?? self
        } else {
            return self
        }
    }
}
