//
//  DomainDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.07.2022.
//

import Foundation

struct DomainDisplayInfo: Hashable, DomainEntity, Equatable, Codable, Identifiable {
    
    var id: String { name }
    
    private(set) var name: String
    private(set) var ownerWallet: String?
    private(set) var blockchain: BlockchainType?
    private(set) var domainPFPInfo: DomainPFPInfo?
    private(set) var state: State
    private(set) var isSetForRR: Bool
    private(set) var order: Int?
    
    init(name: String,
         ownerWallet: String,
         blockchain: BlockchainType? = nil,
         pfpInfo: DomainPFPInfo? = nil,
         state: State = .default,
         order: Int? = nil,
         isSetForRR: Bool) {
        self.name = name
        self.ownerWallet = ownerWallet
        self.blockchain = blockchain
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
    
    init(firebaseDomain: FirebaseDomainDisplayInfo,
         order: Int? = nil) {
        self.name = firebaseDomain.name
        self.ownerWallet = firebaseDomain.ownerAddress
        self.state = .parking(status: firebaseDomain.parkingStatus)
        self.order = order
        self.isSetForRR = false
    }
}

// MARK: - Open methods
extension DomainDisplayInfo {
    var qrCodeURL: URL? { String.Links.domainProfilePage(domainName: name).url }
    var pfpSource: DomainPFPInfo.PFPSource { domainPFPInfo?.source ?? .none }
    var isUpdatingRecords: Bool {
        switch state {
        case .minting, .updatingRecords, .transfer, .updatingReverseResolution:
            return true
        case .default, .parking:
            return false
        }
    }
    var isMinting: Bool { state == .minting }
    var isParked: Bool {
        if case .parking = state {
            return true
        }
        return false
    }
    var isTransferring: Bool { state == .transfer }
    var isPrimary: Bool { order == 0 } /// Primary domain now is the one user has selected to be the first
    var isSubdomain: Bool { name.isSubdomain() }
    
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
    
    func getOwnerWallet() throws -> String {
        guard let ownerWallet else { throw DomainDisplayInfoError.domainWithoutOwnerWallet }
        
        return ownerWallet
    }
}

// MARK: - State
extension DomainDisplayInfo {
    enum State: Hashable, Codable {
        case `default`, minting, updatingRecords, parking(status: DomainParkingStatus), transfer
        case updatingReverseResolution
        
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
            case (.transfer, .transfer):
                return true
            case (.updatingReverseResolution, .updatingReverseResolution):
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
        case normal,
             newNonInteractable(tld: String),
             deprecated(tld: String),
             parked(status: DomainParkingStatus)
    }
    
    var usageType: UsageType {
        if let tld = name.getTldName(), Constants.newNonInteractableTLDs.contains(tld) {
            return .newNonInteractable(tld: tld)
        } else if let tld = name.getTldName(),
                  Constants.deprecatedTLDs.contains(tld) {
            return .deprecated(tld: tld)
        } else if case .parking(let status) = state {
            return .parked(status: status)
        }
        return .normal
    }
    var isInteractable: Bool { usageType == .normal }
    var isAbleToSetAsRR: Bool { usageType == .normal && blockchain == .Matic }
    var isAbleToTransfer: Bool { usageType == .normal && (blockchain == .Matic || blockchain == .Base) }
    var isAvailableForMessaging: Bool {
        switch usageType {
        case .normal:
            return true
        case .newNonInteractable(let tld):
            return tld == Constants.ensDomainTLD
        default:
            return false
        }
    }
}

extension Array where Element == DomainDisplayInfo {
    func interactableItems() -> [DomainDisplayInfo] {
        self.filter({ $0.isInteractable })
    }
    
    func availableForMessagingItems() -> [DomainDisplayInfo] {
        self.filter { $0.isAvailableForMessaging }
    }
    
    func availableForRRItems() -> [DomainDisplayInfo] {
        self.filter { $0.isAbleToSetAsRR }
    }
    
    func requirePNItems() -> [DomainDisplayInfo] {
        self.filter {
            if $0.isAvailableForMessaging {
                return true
            } else if case .parked = $0.usageType {
                return true
            }
            return false
        }
    }
}

extension DomainDisplayInfo {
    func toDomainItem() -> DomainItem {
        DomainItem(name: name, ownerWallet: ownerWallet, blockchain: blockchain)
    }
}

// MARK: - Open methods
extension DomainDisplayInfo {
    enum DomainDisplayInfoError: String, LocalizedError {
        case domainWithoutOwnerWallet
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
