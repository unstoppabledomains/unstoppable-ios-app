//
//  NetworkReachabilityService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation
import SystemConfiguration

protocol NetworkReachabilityServiceProtocol {
    var status: NetworkReachabilityService.Status { get }
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
    func networkStatusChanged(_ status: NetworkReachabilityService.Status)
}

open class NetworkReachabilityService {
            
    // MARK: - Properties
    let reachabilityQueue = DispatchQueue(label: "reachabilityQueue")
    var isReachable: Bool { isReachableOnCellular || isReachableOnEthernetOrWiFi }
    var isReachableOnCellular: Bool { status == .reachable(.cellular) }
    var isReachableOnEthernetOrWiFi: Bool { status == .reachable(.ethernetOrWiFi) }
    var status: Status { flags.map(Status.init) ?? .unknown }
    
    private var flags: SCNetworkReachabilityFlags? {
        var flags = SCNetworkReachabilityFlags()
        
        return (SCNetworkReachabilityGetFlags(reachability, &flags)) ? flags : nil
    }
    private let reachability: SCNetworkReachability
    private var previousStatus: Status = .unknown
    private var listeners: [NetworkReachabilityListenerHolder] = []
    
    // MARK: - Initialization
    convenience init?(host: String) {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }
        
        self.init(reachability: reachability)
    }
    
    convenience init?() {
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)
        
        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero) else { return nil }
        
        self.init(reachability: reachability)
    }
    
    private init(reachability: SCNetworkReachability) {
        self.reachability = reachability
    }
    
    deinit {
        stopListening()
    }

}

// MARK: - Open methods
extension NetworkReachabilityService: NetworkReachabilityServiceProtocol {
    @discardableResult
    func startListening() -> Bool {
        stopListening()
        
        var context = SCNetworkReachabilityContext(version: 0,
                                                   info: Unmanaged.passUnretained(self).toOpaque(),
                                                   retain: nil,
                                                   release: nil,
                                                   copyDescription: nil)
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else { return }
            
            let instance = Unmanaged<NetworkReachabilityService>.fromOpaque(info).takeUnretainedValue()
            instance.notifyListeners(flags)
        }
        
        let queueAdded = SCNetworkReachabilitySetDispatchQueue(reachability, reachabilityQueue)
        let callbackAdded = SCNetworkReachabilitySetCallback(reachability, callback, &context)
        
        // Manually call listener to give initial state, since the framework may not.
        if let currentFlags = flags {
            reachabilityQueue.async {
                self.notifyListeners(currentFlags)
            }
        }
        
        return callbackAdded && queueAdded
    }
    
    func stopListening() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        listeners.removeAll()
    }
    
    func addListener(_ listener: NetworkReachabilityServiceListener) {
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(.init(listener: listener))
        }
    }
    
    func removeListener(_ listener: NetworkReachabilityServiceListener) {
        listeners.removeAll(where: { $0.listener == nil || $0.listener === listener })
    }
}

// MARK: - Private methods
private extension NetworkReachabilityService {
    func notifyListeners(_ flags: SCNetworkReachabilityFlags) {
        let newStatus = Status(flags)
        
        guard self.previousStatus != newStatus else { return }
        
        listeners.forEach { holder in
            holder.listener?.networkStatusChanged(newStatus)
        }
    }
}

// MARK: - Status
extension NetworkReachabilityService {
    enum Status: Equatable {
        case unknown
        case notReachable
        case reachable(ConnectionType)
        
        init(_ flags: SCNetworkReachabilityFlags) {
            guard flags.isActuallyReachable else { self = .notReachable; return }
            
            var networkStatus: Status = .reachable(.ethernetOrWiFi)
            
            if flags.isCellular { networkStatus = .reachable(.cellular) }
            
            self = networkStatus
        }
        
        public enum ConnectionType {
            case ethernetOrWiFi
            case cellular
        }
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
