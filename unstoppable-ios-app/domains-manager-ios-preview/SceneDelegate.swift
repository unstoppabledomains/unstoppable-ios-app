//
//  SceneDelegate.swift
//  manager
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SceneDelegateProtocol {
 

    var window: MainWindow?
    static let shared: SceneDelegateProtocol? = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegateProtocol


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = MainWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        self.window = window
        
        
        let view = HomeTabView(selectedWallet: WalletEntity.mock().first!)
        
        let vc = UIHostingController(rootView: view)
        window.rootViewController = vc
        
        
//        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
//        let nav = CNavigationController(rootViewController: vc)
//        window.rootViewController = nav
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    var interfaceOrientation: UIInterfaceOrientation = .portrait
    
    var sceneActivationState: UIScene.ActivationState = .foregroundActive
    
    func setAppearanceStyle(_ appearanceStyle: UIUserInterfaceStyle) {
        
    }
    
    func authorizeUserOnAppOpening() async throws {
        
    }
    
    func restartOnboarding() {
        
    }
    
    func addListener(_ listener: SceneActivationListener) {
        
    }
    
    func removeListener(_ listener: SceneActivationListener) {
        
    }
    
}

