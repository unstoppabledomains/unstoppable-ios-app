//
//  AppDelegate.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 02.10.2020.
//

import UIKit
import Bugsnag
import Push

var appContext: AppContextProtocol {
    return AppDelegate.shared.appContext
}

protocol AppDelegateProtocol {
    var appContext: AppContextProtocol { get }
    func setAppContextType(_ contextType: AppContextType)
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private(set) lazy var appContext: AppContextProtocol = {
        GeneralAppContext()
    }()
    static let shared: AppDelegateProtocol = UIApplication.shared.delegate as! AppDelegateProtocol

    var syncWalletsPopupShownCount = 0
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        
        Debugger.setAllowedTopicsSet(.debugDefault)
//        CoreDataMessagingStorageService(decrypterService: AESMessagingContentDecrypterService()).clear()
//        MessagingFilesService(decrypterService: AESMessagingContentDecrypterService()).clear()
//        clearImagesCache()
        if TestsEnvironment.isTestModeOn {
            setAppContextType(.mock)
        }
        
        #endif
         
        setup()
        
        appContext.analyticsService.log(event: .appLaunch, withParameters: nil)
        
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
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data ) {
        appContext.notificationsService.didRegisterForRemoteNotificationsWith(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Debugger.printFailure("APNs registration failed: \(error.localizedDescription)", critical: false)
        appContext.notificationsService.unregisterDeviceToken()
    }

}

// MARK: - AppDelegateProtocol
extension AppDelegate: AppDelegateProtocol {
    func setAppContextType(_ contextType: AppContextType) {
        switch contextType {
        case .general:
            self.appContext = GeneralAppContext()
        case .mock:
            #if DEBUG
            self.appContext = MockContext()
            #endif
        }
    }
}

// MARK: - Private methods
private extension AppDelegate {
    func setup() {
        setVersionAndBuildNumber()
        setupAppearance()
        setupBugsnag()
        setupFeatureFlags()
        configureNavBar()
    }
    
    func configureNavBar() {
        UINavigationBar.appearance().scrollEdgeAppearance = UINavigationBarAppearance.udAppearanceWith(isTransparent: true)
        UINavigationBar.appearance().standardAppearance = UINavigationBarAppearance.udAppearanceWith(isTransparent: false)
    }
    
    func setupAppearance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = .backgroundSubtle
    }
    
    func setVersionAndBuildNumber() {
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        if let (oldVersion, newVersion) = getAppVersions(currentVersion: version) {
            setFlagIfUserUpgradedToWalletVersion(oldVersion: oldVersion, newVersion: newVersion)
            clearImagesCacheIfNeeded(oldVersion: oldVersion, newVersion: newVersion)
        }
        
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        UserDefaults.buildVersion = "Build \(version) (\(build)) \(Env.schemeDescription)"
    }
    
    func getAppVersions(currentVersion: String) -> (oldVersion: Version, newVersion: Version)? {
        let oldBuildVersion = UserDefaults.buildVersion
        guard !oldBuildVersion.isEmpty else { return nil }
        
        let components = oldBuildVersion.components(separatedBy: " ")
        
        guard components.count > 2,
              let oldVersion = try? Version.parse(versionString: components[1]),
              let newVersion = try? Version.parse(versionString: currentVersion) else {
            return nil
        }
        
        return (oldVersion, newVersion)
    }
    
    func setFlagIfUserUpgradedToWalletVersion(oldVersion: Version, newVersion: Version) {
        if oldVersion.major <= 4,
           newVersion.major == 5 {
            UserDefaults.didUpdateToWalletVersion = true
        }
    }
    
    func clearImagesCacheIfNeeded(oldVersion: Version, newVersion: Version) {
        if oldVersion.major < 5 ||
            (oldVersion.major == 5 && oldVersion.minor < 4) {
            clearImagesCache()
        }
    }
    
    func clearImagesCache() {
        Task {
            await appContext.imageLoadingService.clearStoredImages()
        }
    }

    func setupBugsnag() {
        Bugsnag.start()
    }
    
    func setupFeatureFlags() {
        _ = appContext.udFeatureFlagsService
    }
}
