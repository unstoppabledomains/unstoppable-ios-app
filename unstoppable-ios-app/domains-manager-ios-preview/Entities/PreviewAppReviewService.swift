//
//  PreviewAppReviewService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import Foundation

final class AppReviewService {
    
    static let shared = AppReviewService()
    
    private init() { }
    
    func appReviewEventDidOccurs(event: AppReviewActionEvent) { }
}
