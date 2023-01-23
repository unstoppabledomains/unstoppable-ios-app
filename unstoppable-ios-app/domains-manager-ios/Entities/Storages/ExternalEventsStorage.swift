//
//  ExternalEventsStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.07.2022.
//

import Foundation

final class ExternalEventsStorage {
    
    static let shared = ExternalEventsStorage()
    
    static let storageFileName = "external-events.data"
    private var storage = SpecificStorage<[ExternalEvent]>(fileName: ExternalEventsStorage.storageFileName)
    
    private init() { }
    
    func getExternalEvents() -> [ExternalEvent] {
        storage.retrieve() ?? []
    }
    
    func saveExternalEvent(_ event: ExternalEvent) {
        var events = getExternalEvents()
        events.append(event)
        set(newEvents: events)
    }
    
    func isEventSaved(_ event: ExternalEvent) -> Bool {
        let events = getExternalEvents()
        return events.contains(event)
    }
    
    func deleteEvent(_ event: ExternalEvent) {
        var events = getExternalEvents()
        events.removeAll(where: { $0 == event })
        set(newEvents: events)
    }
    
    func moveEventToTheEnd(_ event: ExternalEvent) {
        guard isEventSaved(event) else { return }
        
        var events = getExternalEvents()
        if let i = events.firstIndex(of: event) {
            events.remove(at: i)
        }
        events.append(event)
        set(newEvents: events)
    }
    
    func moveEventToTheStart(_ event: ExternalEvent) {
        guard isEventSaved(event) else { return }
        
        var events = getExternalEvents()
        if let i = events.firstIndex(of: event) {
            events.remove(at: i)
        }
        events.insert(event, at: 0)
        set(newEvents: events)
    }
    
    private func set(newEvents: [ExternalEvent]) {
        storage.store(newEvents)
    }
}
