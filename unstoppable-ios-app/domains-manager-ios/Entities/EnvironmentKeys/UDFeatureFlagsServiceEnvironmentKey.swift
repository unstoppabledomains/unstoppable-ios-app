//
//  UDFeatureFlagsServiceEnvironmentKey.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2024.
//

import SwiftUI

private struct UDFeatureFlagsServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue = appContext.udFeatureFlagsService
}

extension EnvironmentValues {
    var udFeatureFlagsService: UDFeatureFlagsServiceProtocol {
        get { self[UDFeatureFlagsServiceEnvironmentKey.self] }
        set { self[UDFeatureFlagsServiceEnvironmentKey.self] = newValue }
    }
}
