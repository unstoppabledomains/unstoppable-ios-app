//
//  UDWalletsServiceEnvironmentKey.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.01.2024.
//

import Foundation
import SwiftUI

private struct UDWalletsServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue = appContext.udWalletsService
}

extension EnvironmentValues {
    var udWalletsService: UDWalletsServiceProtocol {
        get { self[UDWalletsServiceEnvironmentKey.self] }
        set { self[UDWalletsServiceEnvironmentKey.self] = newValue }
    }
}


