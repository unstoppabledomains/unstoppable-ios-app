//
//  NetworkReachabilityServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation
import SystemConfiguration

protocol NetworkReachabilityServiceProtocol {
    var status: NetworkReachabilityStatus { get }
    var isReachable: Bool { get }
    
    @discardableResult
    func startListening() -> Bool
    func stopListening()
    func addListener(_ listener: NetworkReachabilityServiceListener)
    func removeListener(_ listener: NetworkReachabilityServiceListener)
}

final class NetworkReachabilityListenerHolder: Equatable {
    
    weak var listener: NetworkReachabilityServiceListener?
    
    init(listener: NetworkReachabilityServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: NetworkReachabilityListenerHolder, rhs: NetworkReachabilityListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}

protocol NetworkReachabilityServiceListener: AnyObject {
    func networkStatusChanged(_ status: NetworkReachabilityStatus)
}

enum NetworkReachabilityStatus: Equatable {
    case unknown
    case notReachable
    case reachable(ConnectionType)
    
    init(_ flags: SCNetworkReachabilityFlags) {
        guard flags.isActuallyReachable else { self = .notReachable; return }
        
        var networkStatus: NetworkReachabilityStatus = .reachable(.ethernetOrWiFi)
        
        if flags.isCellular { networkStatus = .reachable(.cellular) }
        
        self = networkStatus
    }
    
    public enum ConnectionType {
        case ethernetOrWiFi
        case cellular
    }
}

extension SCNetworkReachabilityFlags {
    var isReachable: Bool { contains(.reachable) }
    var isConnectionRequired: Bool { contains(.connectionRequired) }
    var canConnectAutomatically: Bool { contains(.connectionOnDemand) || contains(.connectionOnTraffic) }
    var canConnectWithoutUserInteraction: Bool { canConnectAutomatically && !contains(.interventionRequired) }
    var isActuallyReachable: Bool { isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction) }
    var isCellular: Bool {
#if os(iOS) || os(tvOS)
        return contains(.isWWAN)
#else
        return false
#endif
    }
    
    /// Human readable `String` for all states, to help with debugging.
    var readableDescription: String {
        let W = isCellular ? "W" : "-"
        let R = isReachable ? "R" : "-"
        let c = isConnectionRequired ? "c" : "-"
        let t = contains(.transientConnection) ? "t" : "-"
        let i = contains(.interventionRequired) ? "i" : "-"
        let C = contains(.connectionOnTraffic) ? "C" : "-"
        let D = contains(.connectionOnDemand) ? "D" : "-"
        let l = contains(.isLocalAddress) ? "l" : "-"
        let d = contains(.isDirect) ? "d" : "-"
        let a = contains(.connectionAutomatic) ? "a" : "-"
        
        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)\(a)"
    }
}
