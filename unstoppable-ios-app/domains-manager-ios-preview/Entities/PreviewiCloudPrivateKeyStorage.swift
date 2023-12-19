//
//  PreviewiCloudPrivateKeyStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

struct iCloudPrivateKeyStorage: PrivateKeyStorage {
    var valet: ValetProtocol
    
    init() {
        valet = PreviewValet()
    }
    
}
