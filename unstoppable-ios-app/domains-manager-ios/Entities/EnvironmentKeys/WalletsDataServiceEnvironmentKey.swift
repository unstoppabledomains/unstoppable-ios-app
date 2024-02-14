//
//  WalletsDataServiceEnvironmentKey.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.01.2024.
//

import Foundation
import SwiftUI

private struct WalletsDataServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue = appContext.walletsDataService
}

extension EnvironmentValues {
    var walletsDataService: WalletsDataServiceProtocol {
        get { self[WalletsDataServiceEnvironmentKey.self] }
        set { self[WalletsDataServiceEnvironmentKey.self] = newValue }
    }
}

