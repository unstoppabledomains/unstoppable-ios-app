//
//  PreviewDomainItem.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

protocol DomainEntity: Equatable {
    var name: String { get }
    var ownerWallet: String? { get }
}

struct DomainItem: DomainEntity {
    var name = ""
    var ownerWallet: String? = ""
}

struct DomainDisplayInfo: Hashable, DomainEntity {
    
    private(set) var name: String
    private(set) var ownerWallet: String?
    private(set) var order: Int?
    var isSetForRR: Bool = false
    var pfpSource: DomainPFPInfo.PFPSource { .none }

}

extension Array where Element == DomainDisplayInfo {
    func interactableItems() -> [DomainDisplayInfo] {
        self
    }
    
    func availableForMessagingItems() -> [DomainDisplayInfo] {
        self
    }
    
    func requirePNItems() -> [DomainDisplayInfo] {
        self
    }
}

struct PublicDomainDisplayInfo: Hashable {
    let walletAddress: String
    let name: String
}

typealias DomainName = String

extension DomainName {
    private func domainComponents() -> [String]? {
        let components = self.components(separatedBy: String.dotSeparator)
        guard components.count >= 2 else {
            Debugger.printFailure("Domain name with no deterctable NS: \(self)", critical: false)
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
        guard let domainName = domainComponents()?.dropLast(1).joined(separator: String.dotSeparator) else {
            Debugger.printFailure("Couldn't get domain name", critical: false)
            return nil
        }
        return domainName
    }
    
    static func isZilByExtension(ext: String) -> Bool {
        ext.lowercased() == "zil"
    }
}
