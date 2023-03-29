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
    private let expiredDomainsNotificationId = "com.unstoppabledomains.notification.expired.domains"
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter
    }()
    private var dateTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return dateFormatter
    }()
    
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
        removeAllLocalNotifications()
        let parkedDomains = domains.filter({ $0.isParked })
        guard !parkedDomains.isEmpty else {
            return
        }
        
        var expiredDomains = [DomainDisplayInfo]()
        var goingToExpireDomains = [GoingToExpireDomain]()
        
        for domain in domains {
            guard case .parking(let status) = domain.state else {
                Debugger.printFailure("Checking local notification for not-parked domain", critical: true)
                continue
            }
            switch status {
            case .claimed, .freeParking:
                continue
            case .parkingExpired:
                expiredDomains.append(domain)
            case .parked(let expiresDate), .parkedButExpiresSoon(let expiresDate), .waitingForParkingOrClaim(let expiresDate):
                goingToExpireDomains.append(GoingToExpireDomain(domain,
                                                                expiresDate: expiresDate))
            }
        }
        
        createNotificationFor(expiredDomains: expiredDomains)
        createNotificationsFor(goingToExpireDomains: goingToExpireDomains)
    }
    
    func removeAllLocalNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func createNotificationFor(expiredDomains: [DomainDisplayInfo]) {
        guard !expiredDomains.isEmpty else { return }
        
        Task {
            let title: String
            if expiredDomains.count == 1 {
                title = expiredDomains[0].name
            } else {
                title = String.Constants.localNotificationParkedMultipleDomainsExpiredTitle.localized()
            }
            let body = String.Constants.localNotificationParkedDomainsExpiredBody.localized()
            let date = dateByAdding(days: 3, atTime: "19:00:00")
            
            await createLocalNotificationWith(identifier: expiredDomainsNotificationId,
                                              title: title,
                                              body: body,
                                              date: date)
            
        }
    }
    
    func createNotificationsFor(goingToExpireDomains: [GoingToExpireDomain]) {
        guard !goingToExpireDomains.isEmpty else { return }
        
        var goingToExpireDomainsWithNotificationDate = [GoingToExpireDomain]()
        
        for var goingToExpireDomain in goingToExpireDomains {
            let expiresDate = goingToExpireDomain.expiresDate
            guard let notificationDate = notificationDateFor(domainExpiresDate: expiresDate) else { continue }
            
            goingToExpireDomain.notificationDate = notificationDate
            goingToExpireDomainsWithNotificationDate.append(goingToExpireDomain)
        }
    }
    
    func notificationDateFor(domainExpiresDate: Date) -> Date? {
        let daysToExpiresDate = calendar.dateComponents([.day], from: Date(), to: domainExpiresDate).day ?? 0
        let notificationsTime = "19:00:00"
        
        let notificationsCheckDays = [30, // One month before expires date
                                      7, // One week before expires date
                                      3, // Three days before expires date
                                      1] // One day before expires date
        for days in notificationsCheckDays {
            if daysToExpiresDate > days {
                return dateByAdding(days: -days, atTime: notificationsTime, to: domainExpiresDate)
            }
        }
        
        return nil
    }
    
    func dateByAdding(days: Int, atTime time: String, to toDate: Date = Date()) -> Date {
        let newDate = calendar.date(byAdding: .day, value: days, to: toDate) ?? Date()
        var newDateString = dateFormatter.string(from: newDate)
        newDateString += " \(time)"
        let notificationDate = dateTimeFormatter.date(from: newDateString) ?? Date()
        return notificationDate
    }
    
    func createLocalNotificationWith(identifier: String,
                                     title: String,
                                     body: String,
                                     date: Date,
                                     userInfo: [String : Any] = [:],
                                     attachments: [UNNotificationAttachment] = [],
                                     calendarComponents: Set<Calendar.Component> = [.weekday, .hour, .minute, .second]) async {
        do {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.badge = 1
            content.attachments = attachments
            content.userInfo = userInfo
            
            let triggerDate = calendar.dateComponents(calendarComponents, from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            try await notificationCenter.add(request)
        } catch {
            Debugger.printFailure("Failed to create local notification with title \(title), date: \(date) with error \(error)", critical: true)
        }
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

// MARK: - Private methods
private extension LocalNotificationsService {
    struct GoingToExpireDomain {
        let domain: DomainDisplayInfo
        let expiresDate: Date
        var notificationDate: Date
        
        init(_ domain: DomainDisplayInfo,
             expiresDate: Date) {
            self.domain = domain
            self.expiresDate = expiresDate
            self.notificationDate = expiresDate
        }
    }
}
