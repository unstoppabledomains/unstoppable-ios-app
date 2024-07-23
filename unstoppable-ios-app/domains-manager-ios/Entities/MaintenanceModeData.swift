//
//  MaintenanceModeData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.07.2024.
//

import Foundation

struct MaintenanceModeData: Codable {
    let isOn: Bool
    let link: String?
    
    var linkURL: URL? { URL(string: link ?? "") }
}
