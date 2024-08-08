//
//  DomainToPurchase.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import SwiftUI

struct DomainToPurchase: Hashable, Identifiable {
    
    var id: String { name }
    
    let name: String
    let price: Int
    let metadata: Data?
    let isTaken: Bool
    let isAbleToPurchase: Bool
    
    var tld: String { name.components(separatedBy: .dotSeparator).last ?? "" }
    var tldCategory: TLDCategory {
        switch tld {
        case Constants.ensDomainTLD:
            return .ens
        case _ where Constants.dnsDomainTLDs.contains(tld):
            return .dns
        default:
            return .uns
        }
    }
    
    enum TLDCategory {
        case uns
        case ens
        case dns
        
        var icon: Image {
            switch self {
            case .uns:
                return .unsTLDLogo
            case .ens:
                return .ensTLDLogo
            case .dns:
                return .dnsTLDLogo
            }
        }
    }
}
