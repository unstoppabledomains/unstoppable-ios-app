//
//  LocalNotificationsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.03.2023.
//

import Foundation
import UserNotifications

final class LocalNotificationsService {
    
    static let shared = LocalNotificationsService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    
    private init() { }
    
}

// MARK: - Open methods
extension LocalNotificationsService {
    
}

// MARK: - DataAggregatorServiceListener
extension LocalNotificationsService: DataAggregatorServiceListener {
    func dataAggregatedWith(result: DataAggregationResult) {
        switch result {
        case .success(let aggregationResult):
            switch aggregationResult {
            case .domainsUpdated(let domains):
                checkNotificationsForParkedDomains(in: domains)
            default:
                return
            }
        case .failure:
            return
        }
    }
}

// MARK: - Private methods
private extension LocalNotificationsService {
    func checkNotificationsForParkedDomains(in domains: [DomainDisplayInfo]) {
        let parkedDomains = domains.filter({ $0.isParked })
        guard !parkedDomains.isEmpty else {
            removeAllLocalNotifications()
            return
        }
        
        parkedDomains.forEach { domain in
            checkLocalNotificationForParkedDomain(domain)
        }
    }
    
    func removeAllLocalNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func checkLocalNotificationForParkedDomain(_ domain: DomainDisplayInfo) {
        guard case .parking(let status) = domain.state else {
            Debugger.printFailure("Checking local notification for not-parked domain", critical: true)
            return
        }
        
        switch status {
        case .claimed:
            return
        case .freeParking:
            return // No expires date => No notification
        case .parkingExpired:
            return // Already expired
        case .parked(let expiresDate), .parkedButExpiresSoon(let expiresDate), .waitingForParkingOrClaim(let expiresDate):
            return
        }
    }
    
    func createLocalNotificationWith(identifier: String,
                                     title: String,
                                     body: String,
                                     date: Date,
                                     userInfo: [String : Any],
                                     attachments: [UNNotificationAttachment],
                                     calendarComponets: Set<Calendar.Component> = [.weekday, .hour, .minute, .second]) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.attachments = attachments
        content.userInfo = userInfo
        
        let triggerDate = calendar.dateComponents(calendarComponets, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try await notificationCenter.add(request)
    }
    
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    func getDeliveredNotification() async -> [UNNotification] {
        await notificationCenter.deliveredNotifications()
    }
    
    func saveImageToDisk(fileIdentifier: String, data: Data, options: [NSObject : AnyObject]?) -> UNNotificationAttachment? {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            let fileURL = folderURL.appendingPathComponent(fileIdentifier).appendingPathExtension("png")
            try data.write(to: fileURL, options: [])
            let attachment = try UNNotificationAttachment(identifier: fileIdentifier, url: fileURL, options: options)
            return attachment
        } catch let error {
            print("error \(error)")
        }
        
        return nil
    }
    
}
