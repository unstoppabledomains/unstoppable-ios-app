//
//  DateFormattingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2022.
//

import Foundation

protocol DateFormattingServiceProtocol {
    func formatICloudBackUpDate(_ date: Date) -> String
    func formatRecentActivityDate(_ date: Date) -> String
}

final class DateFormattingService {
    
    static let shared: DateFormattingServiceProtocol = DateFormattingService()
    
    private let iCloudBackUpDateFormatter = DateFormatter()
    private let recentActivityDateFormatter = DateFormatter()

    private init() {
        setup()
    }
    
}

// MARK: - DateFormattingServiceProtocol
extension DateFormattingService: DateFormattingServiceProtocol {
    func formatICloudBackUpDate(_ date: Date) -> String {
        iCloudBackUpDateFormatter.string(from: date)
    }
    
    func formatRecentActivityDate(_ date: Date) -> String {
        recentActivityDateFormatter.string(from: date)
    }
}

// MARK: - Setup methods
private extension DateFormattingService {
    func setup() {
        setupICloudBackUpDateFormatter()
        setupRecentActivityDateFormatter()
    }
    
    func setupICloudBackUpDateFormatter() {
        iCloudBackUpDateFormatter.dateStyle = .medium
        iCloudBackUpDateFormatter.timeStyle = .none
    }
    
    func setupRecentActivityDateFormatter() {
        recentActivityDateFormatter.dateFormat = "EEEE d, HH:mm"
    }
}
