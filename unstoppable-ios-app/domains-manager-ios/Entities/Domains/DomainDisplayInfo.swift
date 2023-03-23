//
//  DomainDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.07.2022.
//

import Foundation

struct DomainDisplayInfo: Hashable, DomainEntity {
    
    private(set) var name: String
    private(set) var ownerWallet: String?
    private(set) var blockchain: BlockchainType?
    private(set) var domainPFPInfo: DomainPFPInfo?
    private(set) var state: State
    private(set) var isSetForRR: Bool
    private(set) var order: Int?
    
    init(name: String,
         ownerWallet: String,
         pfpInfo: DomainPFPInfo? = nil,
         state: State = .default,
         order: Int? = nil,
         isSetForRR: Bool) {
        self.name = name
        self.ownerWallet = ownerWallet
        self.state = state
        self.domainPFPInfo = pfpInfo
        self.order = order
        self.isSetForRR = isSetForRR
    }
    
    init(domainItem: DomainItem,
         pfpInfo: DomainPFPInfo? = nil,
         state: State = .default,
         order: Int? = nil,
         isSetForRR: Bool) {
        self.name = domainItem.name
        self.blockchain = domainItem.blockchain
        self.ownerWallet = domainItem.ownerWallet
        self.state = state
        self.domainPFPInfo = pfpInfo
        self.order = order
        self.isSetForRR = isSetForRR
    }
}

// MARK: - Open methods
extension DomainDisplayInfo {
    var qrCodeURL: URL? { String.Links.domainProfilePage(domainName: name).url }
    var pfpSource: DomainPFPInfo.PFPSource { domainPFPInfo?.source ?? .none }
    var isUpdatingRecords: Bool { state != .default }
    var isMinting: Bool { state == .minting }
    var isPrimary: Bool { order == 0 } /// Primary domain now is the one user has selected to be the first

    func isReverseResolutionChangeAllowed() -> Bool {
        state == .default
    }
    
    mutating func setState(_ state: State) {
        self.state = state
    }
    
    mutating func setPFPInfo(_ pfpInfo: DomainPFPInfo?) {
        self.domainPFPInfo = pfpInfo
    }
    
    mutating func setOrder(_ order: Int?) {
        self.order = order
    }
}

// MARK: - State
extension DomainDisplayInfo {
    enum State: Hashable {
        case `default`, minting, updatingRecords, parking(status: DomainParkingStatus)
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.default, .default):
                return true
            case (.minting, .minting):
                return true
            case (.updatingRecords, .updatingRecords):
                return true
            case (.parking, .parking):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - UsageType
extension DomainDisplayInfo {
    enum UsageType: Equatable {
        case normal, zil, deprecated(tld: String)
    }
    
    var usageType: UsageType {
        if isZilliqaBased {
            return .zil
        } else if let tld = name.getTldName(),
                  Constants.deprecatedTLDs.contains(tld) {
            return .deprecated(tld: tld)
        }
        return .normal
    }
    var isZilliqaBased: Bool { blockchain == .Zilliqa }
    var isInteractable: Bool { usageType == .normal }
    
}

extension Array where Element == DomainDisplayInfo {
    func interactableItems() -> [DomainDisplayInfo] {
        self.filter({ $0.isInteractable })
    }
}
