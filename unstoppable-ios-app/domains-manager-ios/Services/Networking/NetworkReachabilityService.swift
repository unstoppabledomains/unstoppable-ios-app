//
//  NetworkReachabilityService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation
import SystemConfiguration

open class NetworkReachabilityService {
            
    // MARK: - Properties
    let reachabilityQueue = DispatchQueue(label: "reachabilityQueue")
    var isReachable: Bool { isReachableOnCellular || isReachableOnEthernetOrWiFi }
    var isReachableOnCellular: Bool { status == .reachable(.cellular) }
    var isReachableOnEthernetOrWiFi: Bool { status == .reachable(.ethernetOrWiFi) }
    var status: NetworkReachabilityStatus { flags.map(NetworkReachabilityStatus.init) ?? .unknown }
    
    private var flags: SCNetworkReachabilityFlags? {
        var flags = SCNetworkReachabilityFlags()
        
        return (SCNetworkReachabilityGetFlags(reachability, &flags)) ? flags : nil
    }
    private let reachability: SCNetworkReachability
    private var previousStatus: NetworkReachabilityStatus = .unknown
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
        let newStatus = NetworkReachabilityStatus(flags)
        
        guard self.previousStatus != newStatus else { return }
        
        listeners.forEach { holder in
            holder.listener?.networkStatusChanged(newStatus)
        }
    }
}
