//
//  PreviewAppReviewService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

final class AppReviewService: AppReviewServiceProtocol {
    func requestToWriteReviewInAppStore() {
        
    }
    
    
    static let shared: AppReviewServiceProtocol = AppReviewService()

    private init() { }
    
    func appReviewEventDidOccurs(event: AppReviewActionEvent) { }
}
