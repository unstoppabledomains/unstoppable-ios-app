//
//  HeapAnalyticService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.08.2022.
//

import Foundation

private protocol HeapRequest: Codable {
    var path: String { get }
}

final class HeapAnalyticService {
    
    private let heapApiURL = URL(string: "https://heapanalytics.com/api")!
    private let appId: String = NetworkService.heapAppId
    private let storage = HeapAnalyticRequestsStorage()
    private var timer: Timer?
    private let userID: String

    init(userID: String) {
        self.userID = userID
        setupTimer()
    }
    
}

// MARK: - AnalyticsServiceProtocol
extension HeapAnalyticService: AnalyticsServiceChildProtocol {
    func log(event: Analytics.Event, timestamp: Date, withParameters eventParameters: Analytics.EventParameters?) {
        let bulkEvent = BulkTrackEvent(identity: identity(),
                                       event: event.rawValue,
                                       timestamp: timestamp,
                                       properties: eventParameters)
        Task {
            await storage.storeRequest(.trackEvent(bulkEvent))
        }
    }
    
    func set(userProperties: Analytics.UserProperties) {
        let event = SetUserPropertiesRequest(appId: appId, identity: identity(), properties: userProperties)
        
        Task {
            await storage.storeRequest(.userProperties(event))
        }
    }
}

// MARK: - Private methods
private extension HeapAnalyticService {
    func send(request: HeapRequest) async throws {
        let url = heapApiURL.appendingPathComponent(request.path)
        guard let body = request.jsonString(using: .convertToSnakeCase) else {
            Debugger.printFailure("Failed to encode heap event", critical: true)
            return
        }
        
        _ = try await NetworkService().fetchData(for: url,
                                                 body: body,
                                                 method: .post)
    }
    
    func identity() -> String {
        userID
    }
    
    func setupTimer() {
        Task {
            await MainActor.run {
                timer = Timer.scheduledTimer(withTimeInterval: Constants.updateInterval,
                                             repeats: true,
                                             block: { [weak self] _ in
                    self?.uploadEvents()
                })
            }
        }
    }
    
    func uploadEvents() {
        Task {
            let requests = await storage.getRequests()
            guard !requests.isEmpty else { return }
            
            var trackEvents: [BulkTrackEvent] = []
            var setUserPropertyRequests: [SetUserPropertiesRequest] = []
            
            requests.forEach { request in
                switch request {
                case .trackEvent(let trackEvent):
                    trackEvents.append(trackEvent)
                case .userProperties(let setUserPropertyEvent):
                    setUserPropertyRequests.append(setUserPropertyEvent)
                }
            }
            
            updateUserProperties(setUserPropertyRequests: setUserPropertyRequests)
            uploadTrackEvents(trackEvents)
        }
    }
    
    func updateUserProperties(setUserPropertyRequests: [SetUserPropertiesRequest]) {
        guard !setUserPropertyRequests.isEmpty else { return }

        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                var properties = Analytics.UserProperties()
                setUserPropertyRequests.forEach { request in
                    properties = properties.merging(request.properties, uniquingKeysWith: { $1 })
                }
                let request = SetUserPropertiesRequest(appId: self.appId,
                                                       identity: self.identity(),
                                                       properties: properties)
                
                try await self.send(request: request)
                await self.storage.clearRequests(setUserPropertyRequests.map({ .userProperties($0) }))
            } catch {
                Debugger.printFailure("Failed to update user properties to Heap: \(error.localizedDescription)", critical: false)
            }
        }
    }
    
    func uploadTrackEvents(_ trackEvents: [BulkTrackEvent]) {
        guard !trackEvents.isEmpty else { return }

        Task.detached { [weak self] in
            guard let self = self else { return }
            do {
                let request = BulkTrackEventsRequest(appId: self.appId,
                                                     events: trackEvents)
                
                try await self.send(request: request)
                await self.storage.clearRequests(trackEvents.map({ .trackEvent($0) }))
            } catch {
                Debugger.printFailure("Failed to upload events to Heap: \(error.localizedDescription)", critical: false)
            }
        }
    }
}

// MARK: - Entities
private extension HeapAnalyticService {
    enum RequestType: Codable, Hashable {
        case trackEvent(_ event: BulkTrackEvent)
        case userProperties(_ request: SetUserPropertiesRequest)
    }
    
    struct BulkTrackEventsRequest: HeapRequest, Hashable {
        var path: String { "track" }
        
        let appId: String
        let events: [BulkTrackEvent]
    }
    
    struct BulkTrackEvent: Codable, Hashable {
        
        enum CodingKeys: String, CodingKey {
            case identity = "identity"
            case event = "event"
            case timestamp = "timestamp"
            case properties = "properties"
        }
        
        let identity: String
        let event: String
        var timestamp: Date = Date()
        let properties: Analytics.EventParameters?
        
        init(identity: String, event: String, timestamp: Date = Date(), properties: Analytics.EventParameters?) {
            self.identity = identity
            self.event = event
            self.timestamp = timestamp
            self.properties = properties
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            identity = try container.decode(String.self, forKey: .identity)
            event = try container.decode(String.self, forKey: .event)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            if let properties = try? container.decode([String : String].self, forKey: .properties) {
                var aProperties = Analytics.EventParameters()
                properties.forEach { element in
                    if let parameter = Analytics.Parameters(rawValue: element.key) {
                        aProperties[parameter] = element.value
                    }
                }
                self.properties = aProperties
            } else  {
                self.properties = nil
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(identity, forKey: .identity)
            try container.encode(event, forKey: .event)
            try container.encode(timestamp, forKey: .timestamp)
            
            if let properties = properties {
                let stringDictionary: [String: String] = Dictionary(uniqueKeysWithValues: properties.map { ($0.rawValue, $1) })
                try container.encode(stringDictionary, forKey: .properties)
            }
        }
    }
    
    struct SetUserPropertiesRequest: HeapRequest, Hashable {
        
        enum CodingKeys: String, CodingKey {
            case appId = "app_id"
            case identity = "identity"
            case properties = "properties"
        }
        
        var path: String { "add_user_properties" }
        
        let appId: String
        let identity: String
        let properties: Analytics.UserProperties
        
        internal init(appId: String, identity: String, properties: Analytics.UserProperties) {
            self.appId = appId
            self.identity = identity
            self.properties = properties
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            appId = try container.decode(String.self, forKey: .appId)
            identity = try container.decode(String.self, forKey: .identity)
            let properties = try container.decode([String : String].self, forKey: .properties)
            var aProperties = Analytics.UserProperties()
            properties.forEach { element in
                if let parameter = Analytics.UserProperty(rawValue: element.key) {
                    aProperties[parameter] = element.value
                }
            }
            self.properties = aProperties
            
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(appId, forKey: .appId)
            try container.encode(identity, forKey: .identity)
            
            let stringDictionary: [String: String] = Dictionary(uniqueKeysWithValues: properties.map { ($0.rawValue, $1) })
            try container.encode(stringDictionary, forKey: .properties)
        }
    }
}

private actor HeapAnalyticRequestsStorage {
    
    static let StorageFileName = "heap_analytic_requests.data"
    private var storage = SpecificStorage<[HeapAnalyticService.RequestType]>(fileName: HeapAnalyticRequestsStorage.StorageFileName)

    func storeRequest(_ event: HeapAnalyticService.RequestType) {
        var requests = getRequests()
        requests.append(event)
        set(newRequests: requests)
    }
    
    func getRequests() -> [HeapAnalyticService.RequestType] {
        storage.retrieve() ?? []
    }
    
    func clearRequests(_ events: [HeapAnalyticService.RequestType]) {
        let newRequests = Set(getRequests()).subtracting(events)
        set(newRequests: Array(newRequests))
    }
    
    private func set(newRequests: [HeapAnalyticService.RequestType]) {
        storage.store(newRequests)
    }
    
}
