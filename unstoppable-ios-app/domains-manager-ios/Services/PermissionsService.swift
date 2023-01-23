//
//  PermissionsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import AVFoundation
import Photos
import UIKit

typealias PermissionsServiceCallback = (_ granted: Bool) -> ()

protocol PermissionsServiceProtocol {
    func askPermissionsFor(functionality: PermissionsService.Functionality, in viewController: UIViewController?, shouldShowAlertIfNotGranted: Bool, completion: @escaping PermissionsServiceCallback)
    func askPermissionsFor(functionality: PermissionsService.Functionality, in viewController: UIViewController?, shouldShowAlertIfNotGranted: Bool) async -> Bool
    
    func checkPermissionsFor(functionality: PermissionsService.Functionality, completion: @escaping PermissionsServiceCallback)
    func checkPermissionsFor(functionality: PermissionsService.Functionality) async -> Bool
}

final class PermissionsService { }

//MARK: - PermissionsManagerProtocol
extension PermissionsService: PermissionsServiceProtocol {
    func askPermissionsFor(functionality: PermissionsService.Functionality, in viewController: UIViewController?, shouldShowAlertIfNotGranted: Bool, completion: @escaping PermissionsServiceCallback) {
        switch functionality {
        case .camera:
            checkCameraPermissions(in: viewController, shouldShowAlertIfNotGranted: shouldShowAlertIfNotGranted, completion: completion)
        case .photoLibrary(let options):
            if #available(iOS 14, *) {
                checkPhotoLibraryPermissions(in: viewController, for: options.accessLevel, shouldShowAlertIfNotGranted: shouldShowAlertIfNotGranted, completion: completion)
            } else {
                checkPhotoLibraryPermissions(in: viewController, shouldShowAlertIfNotGranted: shouldShowAlertIfNotGranted, completion: completion)
            }
        case .notifications(let options):
            checkNotificationsPermissions(in: viewController, options: options, shouldShowAlertIfNotGranted: shouldShowAlertIfNotGranted, completion: completion)
        }
    }
    
    func askPermissionsFor(functionality: PermissionsService.Functionality, in viewController: UIViewController?, shouldShowAlertIfNotGranted: Bool) async -> Bool {
        await withSafeCheckedContinuation({ completion in
            askPermissionsFor(functionality: functionality, in: viewController, shouldShowAlertIfNotGranted: shouldShowAlertIfNotGranted) { granted in
                completion(granted)
            }
        })
    }
    
    func checkPermissionsFor(functionality: PermissionsService.Functionality, completion: @escaping PermissionsServiceCallback) {
        switch functionality {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            completion(status == .authorized)
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus()
            completion(status == .authorized)
        case .notifications:
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                let status = settings.authorizationStatus
                completion(status == .authorized)
            }
        }
    }
    
    func checkPermissionsFor(functionality: PermissionsService.Functionality) async -> Bool {
        await withSafeCheckedContinuation({ completion in
            checkPermissionsFor(functionality: functionality) { granted in
                completion(granted)
            }
        })
    }
}

// MARK: - Private methods
private extension PermissionsService {
    func checkCameraPermissions(in controller: UIViewController?, shouldShowAlertIfNotGranted: Bool, completion: @escaping PermissionsServiceCallback) {
        let analyticsName = Functionality.camera.analyticsName
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            appContext.analyticsService.log(event: .permissionsRequested,
                                        withParameters: [.permissionsType: analyticsName])
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [unowned self] (granted) in
                if granted {
                    appContext.analyticsService.log(event: .permissionsGranted,
                                                withParameters: [.permissionsType: analyticsName])
                    completion(true)
                } else {
                    appContext.analyticsService.log(event: .permissionsDeclined,
                                                withParameters: [.permissionsType: analyticsName])
                    DispatchQueue.main.async { [unowned self] in
                        self.presentCameraPermissionsErrorController(in: controller, ifNeeded: shouldShowAlertIfNotGranted)
                    }
                    completion(false)
                }
            })
        } else if status == .denied {
            presentCameraPermissionsErrorController(in: controller, ifNeeded: shouldShowAlertIfNotGranted)
            completion(false)
        } else {
            completion(true)
        }
    }
    
    @available(iOS 14, *)
    func checkPhotoLibraryPermissions(in controller: UIViewController?, for accessLevel: PHAccessLevel, shouldShowAlertIfNotGranted: Bool, completion: @escaping PermissionsServiceCallback) {
        let analyticsName = Functionality.photoLibrary(options: .addOnly).analyticsName
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            appContext.analyticsService.log(event: .permissionsRequested,
                                        withParameters: [.permissionsType: analyticsName])
            PHPhotoLibrary.requestAuthorization(for: accessLevel) { [unowned self] (newStatus) in
                if newStatus == .authorized {
                    appContext.analyticsService.log(event: .permissionsGranted,
                                                withParameters: [.permissionsType: analyticsName])
                    completion(true)
                } else {
                    appContext.analyticsService.log(event: .permissionsDeclined,
                                                withParameters: [.permissionsType: analyticsName])
                    DispatchQueue.main.async { [unowned self] in
                        self.presentPhotoLibraryPermissionsErrorController(in: controller, ifNeeded: shouldShowAlertIfNotGranted)
                    }
                    completion(false)
                }
            }
        } else if status == .denied {
            presentPhotoLibraryPermissionsErrorController(in: controller, ifNeeded: shouldShowAlertIfNotGranted)
            completion(false)
        } else {
            completion(true)
        }
    }
    
    func checkPhotoLibraryPermissions(in controller: UIViewController?, shouldShowAlertIfNotGranted: Bool, completion: @escaping PermissionsServiceCallback) {
        let analyticsName = Functionality.notifications(options: []).analyticsName
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            appContext.analyticsService.log(event: .permissionsRequested,
                                        withParameters: [.permissionsType: analyticsName])
            PHPhotoLibrary.requestAuthorization { [unowned self] (newStatus) in
                if newStatus == .authorized {
                    appContext.analyticsService.log(event: .permissionsGranted,
                                                withParameters: [.permissionsType: analyticsName])
                    completion(true)
                } else {
                    appContext.analyticsService.log(event: .permissionsDeclined,
                                                withParameters: [.permissionsType: analyticsName])
                    DispatchQueue.main.async { [unowned self] in
                        self.presentPhotoLibraryPermissionsErrorController(in: controller, ifNeeded: shouldShowAlertIfNotGranted)
                    }
                    completion(false)
                }
            }
        } else if status == .denied {
            presentPhotoLibraryPermissionsErrorController(in: controller, ifNeeded: shouldShowAlertIfNotGranted)
            completion(false)
        } else {
            completion(true)
        }
    }
    
    func checkNotificationsPermissions(in viewController: UIViewController?, options: UNAuthorizationOptions, shouldShowAlertIfNotGranted: Bool, completion: @escaping PermissionsServiceCallback) {
        func checkGrantedStatusAndReturnIfHasViewController(granted: Bool) {
            DispatchQueue.main.async { [weak self] in
                if let viewController = viewController {
                    if granted {
                        completion(true)
                    } else {
                        self?.presentNotificationsPermissionsErrorController(in: viewController, ifNeeded: shouldShowAlertIfNotGranted)
                        completion(false)
                    }
                }
            }
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            let authorizationStatus = settings.authorizationStatus
            switch authorizationStatus {
            case .authorized:
                checkGrantedStatusAndReturnIfHasViewController(granted: true)
            case .denied:
                checkGrantedStatusAndReturnIfHasViewController(granted: false)
            default:
                UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (granted, _) in
                    checkGrantedStatusAndReturnIfHasViewController(granted: granted)
                })
            }
        }
    }
}

//MARK: - Private methods
private extension PermissionsService {
    func presentCameraPermissionsErrorController(in controller: UIViewController?, ifNeeded: Bool) {
        if ifNeeded {
            presentErrorPermissionsAlertWith(message: String.Constants.errCameraPermissions.localized(), in: controller)
        }
    }
    
    func presentPhotoLibraryPermissionsErrorController(in controller: UIViewController?, ifNeeded: Bool) {
        if ifNeeded {
            presentErrorPermissionsAlertWith(message: String.Constants.errPhotoLibraryPermissions.localized(), in: controller)
        }
    }
    
    func presentNotificationsPermissionsErrorController(in controller: UIViewController?, ifNeeded: Bool) {
        if ifNeeded {
            presentErrorPermissionsAlertWith(message: String.Constants.errNotificationsPermissions.localized(), in: controller)
        }
    }
    
    func presentErrorPermissionsAlertWith(message: String?, in controller: UIViewController?) {
        DispatchQueue.main.async {
            let settingsAction = UIAlertAction(title: String.Constants.settings.localized(), style: .destructive, handler: { (action) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            })
            let okAction = UIAlertAction(title: String.Constants.ok.localized(), style: .default, handler: nil)
            
            let alert = UIAlertController(title: "\(String.Constants.warning.localized())!", message: message, preferredStyle: .alert)
            alert.addAction(settingsAction)
            alert.addAction(okAction)
            controller?.present(alert, animated: true, completion: nil)
        }
    }
}

extension PermissionsService {
    enum Functionality {
        case camera, photoLibrary(options: PhotoLibraryPermissionsOptions), notifications(options: UNAuthorizationOptions)
        
        var analyticsName: String {
            switch self {
            case .camera:
                return "camera"
            case .photoLibrary:
                return "photoLibrary"
            case .notifications:
                return "notifications"
            }
        }
    }
    
    enum PhotoLibraryPermissionsOptions {
        case addOnly, readWrite
        
        @available(iOS 14, *)
        var accessLevel: PHAccessLevel {
            switch self {
            case .addOnly: return .addOnly
            case .readWrite: return .readWrite
            }
        }
        
    }
}
