//
//  AppReviewServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

protocol AppReviewServiceProtocol {
    func appReviewEventDidOccurs(event: AppReviewActionEvent)
    func requestToWriteReviewInAppStore()
}
