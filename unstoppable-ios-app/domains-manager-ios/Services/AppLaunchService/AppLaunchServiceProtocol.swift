//
//  AppLaunchServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.08.2022.
//

import Foundation

protocol AppLaunchServiceProtocol {
    func startWith(sceneDelegate: SceneDelegateProtocol,
                   walletConnectServiceV2: WalletConnectServiceV2Protocol,
                   completion: @escaping EmptyCallback)
    func addListener(_ listener: AppLaunchServiceListener)
    func removeListener(_ listener: AppLaunchServiceListener)
}


protocol AppLaunchServiceListener: AnyObject {
    func appLaunchServiceDidUpdateAppVersion()
}

final class AppLaunchListenerHolder: Equatable {
    
    weak var listener: AppLaunchServiceListener?
    
    init(listener: AppLaunchServiceListener) {
        self.listener = listener
    }
    
    static func == (lhs: AppLaunchListenerHolder, rhs: AppLaunchListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
