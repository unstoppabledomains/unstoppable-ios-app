//
//  MPCWallet2FASetupDetails.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.10.2024.
//

import Foundation

struct MPCWallet2FASetupDetails {
    let secret: String
    let email: String
    private let fullSecret: String
    
    init(secret: String, email: String) {
        self.fullSecret = secret
        // Some Auth apps like Google does not work with full base64 format.
        self.secret = secret.replacingOccurrences(of: "=", with: "")
        self.email = email
    }
    
    func buildAuthPath() -> String {
        let issuer = "Unstoppable"
        return "otpauth://totp/\(email)?secret=\(secret)&issuer=\(issuer)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
    func buildAuthURL() -> URL? {
        URL(string: buildAuthPath())
    }
}
