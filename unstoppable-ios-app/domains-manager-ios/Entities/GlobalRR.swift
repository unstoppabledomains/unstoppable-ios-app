//
//  GlobalRR.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.08.2023.
//

import Foundation

struct GlobalRR: Codable {
    let address: String
    let name: String
    let avatarUrl: URL?
    let imageUrl: URL?
    
    var pfpURLToUse: URL? { imageUrl ?? avatarUrl }
}
