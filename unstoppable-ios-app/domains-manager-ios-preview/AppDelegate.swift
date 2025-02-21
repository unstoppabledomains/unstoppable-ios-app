//
//  AppDelegate.swift
//  manager
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit


var appContext: AppContextProtocol {
    previewContext
}


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setup()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

// MARK: - Private methods
private extension AppDelegate {
    func setup() {
        configureNavBar()
        setupAppearance()
    }
    
    func configureNavBar() {
        UINavigationBar.appearance().scrollEdgeAppearance = UINavigationBarAppearance.udAppearanceWith(isTransparent: true)
        UINavigationBar.appearance().standardAppearance = UINavigationBarAppearance.udAppearanceWith(isTransparent: false)
    }
    
    func setupAppearance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = .backgroundSubtle
    }
}
