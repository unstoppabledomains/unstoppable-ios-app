//
//  AppReviewService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.01.2023.
//

import Foundation
import UIKit
import StoreKit

final class AppReviewService {
    
    static let shared: AppReviewServiceProtocol = AppReviewService()
    
    @UserDefaultsValue(key: AppReviewStorageKey.lastVersionPromptedForReviewKey, defaultValue: "") var lastVersionPromptedForReview: String
    @UserDefaultsValue(key: AppReviewStorageKey.appReviewEventsCountKey, defaultValue: 0) var appReviewEventsCount: Int
    @UserDefaultsValue(key: AppReviewStorageKey.numberOfTimesReviewWasRequestedKey, defaultValue: 0) var numberOfTimesReviewWasRequested: Int
    /// - Key: number of times review are requested
    /// - Value: number of events required
    #if DEBUG
    private let numberOfEventsToRequestReviewMap: [Int : Int] = [0 : 20]
    private let defaultNumberOfEventsToRequestReview = 50
    #else
    private let numberOfEventsToRequestReviewMap: [Int : Int] = [0 : 20]
    private let defaultNumberOfEventsToRequestReview = 50
    #endif
    
    private init() { }
    
}

// MARK: - AppReviewServiceProtocol
extension AppReviewService: AppReviewServiceProtocol {
    func appReviewEventDidOccurs(event: AppReviewActionEvent) {
        if event.shouldFireRequestDirectly {
            appReviewEventsCount = 0
            requestAppReview()
        } else {
            appReviewEventsCount += 1
            requestAppReviewIfNeeded()
        }
    }
    
    func requestToWriteReviewInAppStore() {
        guard let writeReviewURL = String.Links.writeAppStoreReview(appId: Constants.appStoreAppId).url else {
            Debugger.printFailure("Failed to create Write AppStore review URL", critical: true)
            return
        }
        
        Task { @MainActor in
            UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Private methods
private extension AppReviewService {
    func requestAppReviewIfNeeded() {
        let requiredNumberOfEvents = numberOfEventsToRequestReviewMap[numberOfTimesReviewWasRequested] ?? defaultNumberOfEventsToRequestReview
        
        if appReviewEventsCount >= requiredNumberOfEvents && isValidAppVersionToRequestReview() {
            appReviewEventsCount = 0
            requestAppReview()
        }
    }
    
    func isValidAppVersionToRequestReview() -> Bool {
        #if DEBUG
//        return true
        #endif
        
        if lastVersionPromptedForReview.isEmpty { /// Never requested
            return true
        }
        
        do {
            let lastPromptedVersion = try Version.parse(versionString: lastVersionPromptedForReview)
            let currentAppVersion = try Version.getCurrent()
            
            return currentAppVersion > lastPromptedVersion
        } catch {
            Debugger.printFailure("Failed to validate app version to submit review with error: \(error.localizedDescription). Current version: \(Version.getCurrentAppVersionString() ?? ""). Last used version: \(lastVersionPromptedForReview)", critical: true)
            return false
        }
    }
    
    func requestAppReview() {
        Task { @MainActor in
            guard let windowScene = SceneDelegate.shared?.window?.windowScene else {
                Debugger.printFailure("Failed to get window scene to request app review", critical: true)
                return
            }
            
            appContext.analyticsService.log(event: .showRateAppRequest, withParameters: nil)
            try? await Task.sleep(seconds: 1) // Apple recommend to wait for second before showing review request
            updateLastVersionPromptedForReviewToCurrent()
            numberOfTimesReviewWasRequested += 1

            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    func updateLastVersionPromptedForReviewToCurrent() {
        do {
            lastVersionPromptedForReview = try Version.getCurrentAppVersionStringThrowing()
        } catch {
            Debugger.printFailure("Failed to update last version prompted for review with error: \(error.localizedDescription)", critical: true)
        }
    }
}

private enum AppReviewStorageKey: String {
    case appReviewEventsCountKey
    case lastVersionPromptedForReviewKey
    case numberOfTimesReviewWasRequestedKey
}
