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
    private let dateFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter
    private let parkingStatusNotificationHour = 19

    private init() {
        let locale = Locale(identifier: "en_US_POSIX")

        dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = locale
        dateTimeFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
    }
    
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
     
        var expiredDomains = [DomainDisplayInfo]()
        var goingToExpireDomains = [GoingToExpireDomain]()
        
        for domain in domains {
            guard case .parking(let status) = domain.state else {
                continue
            }
            switch status {
            case .claimed, .freeParking:
                continue
            case .parkingExpired:
                expiredDomains.append(domain)
            case .parked(let expiresDate), .parkedButExpiresSoon(let expiresDate), .parkingTrial(let expiresDate):
                goingToExpireDomains.append(GoingToExpireDomain(domain,
                                                                expiresDate: expiresDate))
            }
        }
        
        createNotificationFor(expiredDomains: expiredDomains)
        createNotificationsFor(goingToExpireDomains: goingToExpireDomains)
    }
    
    func removeAllLocalNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func createNotificationFor(expiredDomains: [DomainDisplayInfo]) {
        guard !expiredDomains.isEmpty else { return }
        
        Task {
            let expiredDomainsCount = expiredDomains.count
            let title: String
            if expiredDomainsCount == 1 {
                title = String.Constants.localNotificationParkedSingleDomainExpiredTitle.localized(expiredDomains[0].name)
            } else {
                title = String.Constants.localNotificationParkedMultipleDomainsExpiredTitle.localized(expiredDomainsCount)
            }
            let body = String.Constants.localNotificationParkedDomainsExpiredBody.localized()
            let date = dateByAdding(days: 3, atTime: "\(parkingStatusNotificationHour):00:00")
            
            await createLocalNotificationWith(identifier: expiredDomainsNotificationId,
                                              title: title,
                                              body: body,
                                              date: date,
                                              userInfo: domainParkingStatusNotificationUserInfo())
            
        }
    }
    
    func createNotificationsFor(goingToExpireDomains: [GoingToExpireDomain]) {
        guard !goingToExpireDomains.isEmpty else { return }
        
        var goingToExpireDomainsNotificationDetails = [GoingToExpireDomainNotificationDetails]()
        
        for goingToExpireDomain in goingToExpireDomains {
            let domain = goingToExpireDomain.domain
            let expiresDate = goingToExpireDomain.expiresDate
            guard let notificationDetails = notificationDetailsFor(domain: domain,
                                                                   expiresDate: expiresDate) else { continue }
            
            goingToExpireDomainsNotificationDetails.append(notificationDetails)
        }
       
        let groupedNotificationDetails = [NotificationDateWithPeriod : [GoingToExpireDomainNotificationDetails]].init(grouping: goingToExpireDomainsNotificationDetails, by: { $0.notificationDateWithPeriod })
        
        for (notificationDate, notificationsDetails) in groupedNotificationDetails {
            guard let notificationDetails = notificationsDetails.first else {
                Debugger.printFailure("Fail state", critical: true)
                continue
            }
            
            let numberOfNotifications = notificationsDetails.count
            let domainsPlural = String.Constants.pluralDomains.localized(numberOfNotifications)
            let expiresInLocalized = notificationDetails.notificationPeriod.expiresInLocalized
            let expirePlural = String.Constants.pluralExpire.localized(numberOfNotifications)
            
            
            let title: String
            let body = String.Constants.localNotificationParkedDomainsExpiresInBody.localized(domainsPlural, expirePlural, expiresInLocalized)
            if numberOfNotifications == 1 {
                title = String.Constants.localNotificationParkedSingleDomainExpiresTitle.localized(notificationDetails.domain.name) 
            } else {
                title = String.Constants.localNotificationParkedMultipleDomainsExpiresTitle.localized(numberOfNotifications)
            }
            
            Task {
                await createLocalNotificationWith(identifier: notificationDetails.domain.name,
                                                  title: title,
                                                  body: body,
                                                  date: notificationDate.notificationDate,
                                                  userInfo: domainParkingStatusNotificationUserInfo())
            }
        }
    }
    
    func notificationDetailsFor(domain: DomainDisplayInfo,
                             expiresDate: Date) -> GoingToExpireDomainNotificationDetails? {

        var currentDate = Date()
        let hours = calendar.component(.hour, from: currentDate)
        if hours >= parkingStatusNotificationHour {
            /// Skip current day in counting notification days diff because it is already later than notification time
            /// Example:
            /// Domain expire date: Jan 2nd
            /// Today is a Jan 1st.
            /// Raw time diff will be = 1 day
            /// If today's time is earlier than notificationHour, we can set notification to one day before expiration on today at notificationHour
            /// But if today's time is later than notificationHour, we will schedule notification to the past time.
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? Date()
        }
        
        let daysToExpiresDate = calendar.dateComponents([.day], from: calendar.startOfDay(for: currentDate), to: calendar.startOfDay(for: expiresDate)).day ?? 0
        let notificationPeriods = DomainExpiresNotificationPeriod.allCases
       
        for period in notificationPeriods {
            let daysCount = period.daysCount
            if daysToExpiresDate >= daysCount {
                let notificationTime = "\(parkingStatusNotificationHour):00:00"
                let notificationDate = dateByAdding(days: -daysCount, atTime: notificationTime, to: expiresDate)
                return .init(domain: domain,
                             notificationDate: notificationDate,
                             notificationPeriod: period)
            }
        }
        
        return nil
    }
    
    func dateByAdding(days: Int, atTime time: String, to toDate: Date = Date()) -> Date {
        let newDate = calendar.date(byAdding: .day, value: days, to: toDate) ?? Date()
        var newDateString = dateFormatter.string(from: newDate)
        newDateString += " \(time)"
        let notificationDate = dateTimeFormatter.date(from: newDateString) ?? toDate
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
            content.attachments = attachments
            content.userInfo = userInfo
            
            let triggerDate = calendar.dateComponents(calendarComponents, from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            Debugger.printInfo(topic: .LocalNotification, "Will schedule local notification with Title: '\(title)'. Body: \(body). Notification date: \(date)")
            try await notificationCenter.add(request)
        } catch {
            Debugger.printFailure("Failed to create local notification with title \(title), date: \(date) with error \(error)", critical: true)
        }
    }
    
    func domainParkingStatusNotificationUserInfo() -> [String : Any] {
        ["type" : ExternalEvent.PushNotificationType.parkingStatusLocal.rawValue]
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
            Debugger.printFailure("Failed to save image to disk for local notification with error: \(error.localizedDescription)")
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
    
    struct GoingToExpireDomainNotificationDetails {
        let domain: DomainDisplayInfo
        let notificationDate: Date
        let notificationPeriod: DomainExpiresNotificationPeriod
        
        var notificationDateWithPeriod: NotificationDateWithPeriod {
            .init(notificationDate: notificationDate, period: notificationPeriod)
        }
    }
    
    struct NotificationDateWithPeriod: Hashable {
        let notificationDate: Date
        let period: DomainExpiresNotificationPeriod
    }
    
    enum DomainExpiresNotificationPeriod: CaseIterable, Hashable {
        case month
        case week
        case threeDays
        case oneDay
        
        var daysCount: Int {
            switch self {
            case .month:
                return 30
            case .week:
                return 7
            case .threeDays:
                return 3
            case .oneDay:
                return 1
            }
        }
        
        var expiresInLocalized: String {
            switch self {
            case .month:
                return String.Constants.localNotificationParkingExpirePeriodInOneMonth.localized()
            case .week:
                return String.Constants.localNotificationParkingExpirePeriodInOneWeek.localized()
            case .threeDays:
                return String.Constants.localNotificationParkingExpirePeriodInThreeDays.localized()
            case .oneDay:
                return String.Constants.localNotificationParkingExpirePeriodInTomorrow.localized()
            }
        }
    }
}
