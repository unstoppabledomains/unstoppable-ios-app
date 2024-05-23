//
//  SceneDelegateProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import UIKit

@MainActor
protocol SceneDelegateProtocol {
    var interfaceOrientation: UIInterfaceOrientation { get }
    var window: MainWindow? { get }
    var sceneActivationState: UIScene.ActivationState { get }
    
    func isAuthorizing() async -> Bool 
    func setAppearanceStyle(_ appearanceStyle: UIUserInterfaceStyle)
    func authorizeUserOnAppOpening() async throws
    func restartOnboarding()
    
    func addListener(_ listener: SceneActivationListener)
    func removeListener(_ listener: SceneActivationListener)
}


typealias SceneActivationState = UIScene.ActivationState

protocol SceneActivationListener: AnyObject {
    func didChangeSceneActivationState(to state: SceneActivationState)
}

final class SceneActivationListenerHolder: Equatable {
    
    weak var listener: SceneActivationListener?
    
    init(listener: SceneActivationListener) {
        self.listener = listener
    }
    
    static func == (lhs: SceneActivationListenerHolder, rhs: SceneActivationListenerHolder) -> Bool {
        guard let lhsListener = lhs.listener,
              let rhsListener = rhs.listener else { return false }
        
        return lhsListener === rhsListener
    }
    
}
