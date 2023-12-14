//
//  ExternalEventsServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation

public enum ExternalEventReceivedState {
    case foreground, background, foregroundAction
}

protocol ExternalEventsServiceProtocol {
    func receiveEvent(_ event: ExternalEvent, receivedState: ExternalEventReceivedState)
    func checkPendingEvents()
    
    func addListener(_ listener: ExternalEventsServiceListener)
    func removeListener(_ listener: ExternalEventsServiceListener)
}

protocol ExternalEventsServiceListener: AnyObject {
    func didReceive(event: ExternalEvent)
}

final class ExternalEventsListenerHolder: Equatable {
    
    weak var listener: ExternalEventsServiceListener?
    
    init(listener: ExternalEventsServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: ExternalEventsListenerHolder, rhs: ExternalEventsListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

typealias ExternalEventUIHandleCompletion = (Bool) -> ()

@MainActor
protocol ExternalEventsUIHandler {
    func handle(uiFlow: ExternalEventUIFlow) async throws
}
