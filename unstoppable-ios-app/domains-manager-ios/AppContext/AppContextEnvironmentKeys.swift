//
//  AppContextEnvironmentKeys.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import SwiftUI

private struct DataAggregatorServiceKey: EnvironmentKey {
    static let defaultValue = appContext.dataAggregatorService
}

extension EnvironmentValues {
    var dataAggregatorService: DataAggregatorServiceProtocol {
        get { self[DataAggregatorServiceKey.self] }
        set { self[DataAggregatorServiceKey.self] = newValue }
    }
}
