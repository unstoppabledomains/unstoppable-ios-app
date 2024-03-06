//
//  AppContextEnvironmentKeys.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.11.2023.
//

import SwiftUI

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


// MARK: - Analytics View Name
private struct AnalyticsAdditionalPropertiesKey: EnvironmentKey {
    static let defaultValue = Analytics.EventParameters()
}

extension EnvironmentValues {
    var analyticsAdditionalProperties: Analytics.EventParameters {
        get { self[AnalyticsAdditionalPropertiesKey.self] }
        set { self[AnalyticsAdditionalPropertiesKey.self] = newValue }
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

// MARK: - Image loading service
private struct FirebaseDomainsServiceKey: EnvironmentKey {
    static let defaultValue = appContext.firebaseParkedDomainsService
}

extension EnvironmentValues {
    var firebaseParkedDomainsService: FirebaseDomainsServiceProtocol {
        get { self[FirebaseDomainsServiceKey.self] }
        set { self[FirebaseDomainsServiceKey.self] = newValue }
    }
}

// MARK: - User profile service
private struct UserProfileServiceKey: EnvironmentKey {
    static let defaultValue = appContext.userProfileService
}

extension EnvironmentValues {
    var userProfileService: UserProfileServiceProtocol {
        get { self[UserProfileServiceKey.self] }
        set { self[UserProfileServiceKey.self] = newValue }
    }
}

// MARK: - Domain profiles service
private struct DomainProfilesServiceKey: EnvironmentKey {
    static let defaultValue = appContext.domainProfilesService
}

extension EnvironmentValues {
    var domainProfilesService: DomainProfilesServiceProtocol {
        get { self[DomainProfilesServiceKey.self] }
        set { self[DomainProfilesServiceKey.self] = newValue }
    }
}
