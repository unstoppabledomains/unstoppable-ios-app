//
//  AppContextEnvironmentKeys.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import SwiftUI

// MARK: - Data aggregator service
private struct DataAggregatorServiceKey: EnvironmentKey {
    static let defaultValue = appContext.dataAggregatorService
}

extension EnvironmentValues {
    var dataAggregatorService: DataAggregatorServiceProtocol {
        get { self[DataAggregatorServiceKey.self] }
        set { self[DataAggregatorServiceKey.self] = newValue }
    }
}

// MARK: - Analytics View Name
private struct AnalyticsViewNameKey: EnvironmentKey {
    static let defaultValue = Analytics.ViewName.unspecified
}

extension EnvironmentValues {
    var analyticsViewName: Analytics.ViewName {
        get { self[AnalyticsViewNameKey.self] }
        set { self[AnalyticsViewNameKey.self] = newValue }
    }
}

// MARK: - Image loading service
private struct ImageLoadingServiceKey: EnvironmentKey {
    static let defaultValue = appContext.imageLoadingService
}

extension EnvironmentValues {
    var imageLoadingService: ImageLoadingServiceProtocol {
        get { self[ImageLoadingServiceKey.self] }
        set { self[ImageLoadingServiceKey.self] = newValue }
    }
}
