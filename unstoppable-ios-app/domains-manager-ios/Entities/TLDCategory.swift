//
//  TLDCategory.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2024.
//

import SwiftUI

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
    
    static func categoryFor(tld: String) -> TLDCategory {
        switch tld {
        case Constants.ensDomainTLD:
            return .ens
        case _ where Constants.dnsDomainTLDs.contains(tld):
            return .dns
        default:
            return .uns
        }
    }
}
