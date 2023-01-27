//
//  AppReviewService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.01.2023.
//

import Foundation
import UIKit
import StoreKit

protocol AppReviewServiceProtocol { }

final class AppReviewService {
    
    static let shared: AppReviewServiceProtocol = AppReviewService()
    
    @UserDefaultsValue(key: AppReviewStorageKey.lastVersionPromptedForReviewKey, defaultValue: "") var lastVersionPromptedForReviewKey: String
    @UserDefaultsValue(key: AppReviewStorageKey.appReviewEventsCountKey, defaultValue: 0) var appReviewEventsCountKey: Int

    
    private init() { }
    
}

// MARK: - AppReviewServiceProtocol
extension AppReviewService: AppReviewServiceProtocol {
    
}

// MARK: - Private methods
private extension AppReviewService {
    func requestAppReview() {
        Task { @MainActor in
            guard let windowScene = SceneDelegate.shared?.window?.windowScene else {
                Debugger.printFailure("Failed to get window scene to request app review", critical: true)
                return
            }
            
            if #available(iOS 14.0, *) {
                SKStoreReviewController.requestReview(in: windowScene)
            } else {
                SKStoreReviewController.requestReview()
            }
        }
    }
    
    func requestToWriteReviewInAppStore() {
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(Constants.appStoreAppId)?action=write-review") else {
            Debugger.printFailure("Failed to create Write AppStore review URL", critical: true)
            return
        }
        
        Task { @MainActor in
            UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
        }
    }
}

enum AppReviewActionEvent {
    
}

private enum AppReviewStorageKey: String {
    case appReviewEventsCountKey
    case lastVersionPromptedForReviewKey
}
