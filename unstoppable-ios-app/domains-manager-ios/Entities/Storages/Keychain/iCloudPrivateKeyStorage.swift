//
//  iCloudPrivateKeyStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.06.2023.
//

import Foundation
import Valet

struct iCloudPrivateKeyStorage: PrivateKeyStorage {
    let valet: ValetProtocol
    static let iCloudName = "unstoppable-icloud-storage"
    init() {
        valet = Valet.iCloudValet(with: Identifier(nonEmpty: Self.iCloudName)!,
                                  accessibility: .whenUnlocked)
    }
}
