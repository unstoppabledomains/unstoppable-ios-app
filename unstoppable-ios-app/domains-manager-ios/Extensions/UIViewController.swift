//
//  UIViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.04.2022.
//

import UIKit

extension UIViewController {
    
    enum Storyboards: String {
        case home = "Home"
        case tutorial = "Tutorial"
        case protectWallet = "ProtectWallet"
        case happyEnd = "HappyEnd"
        
        var name: String { rawValue }
    }
    
    static func storyboardInstance(from storyboard: Storyboards) -> Self {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: .main)
        let identifier = String(describing: self)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier) as! Self
        
        return vc
    }

    class func nibInstance() -> Self {
        let nibName = String(describing: self).components(separatedBy: "<")[0]
        return self.nibInstance(nibName: nibName)
    }
  
    class func nibInstance(nibName: String) -> Self {
        return self.init(nibName: nibName, bundle: nil)
    }
    
    var isPresentingAsPageSheet: Bool {
        if let nav = navigationController {
            return nav.isPresentingAsPageSheet
        }
        return presentingViewController != nil && modalPresentationStyle == .pageSheet
    }
}

extension UIViewController {
    final class BarButtonItemWithoutMenu: UIBarButtonItem {
        override var menu: UIMenu? {  get { nil } set { } }
    }
    
    func customiseNavigationBackButton(image: UIImage = BaseViewController.NavBackIconStyle.arrow.icon) {
        let backButtonBackgroundImage = image.withAlignmentRectInsets(.init(top: 0, left: -8, bottom: 0, right: 0))
        self.navigationController?.navigationBar.standardAppearance.setBackIndicatorImage(backButtonBackgroundImage,
                                                                                          transitionMaskImage: backButtonBackgroundImage)
        self.navigationController?.navigationBar.scrollEdgeAppearance?.setBackIndicatorImage(backButtonBackgroundImage,
                                                                                             transitionMaskImage: backButtonBackgroundImage)
    }

    func showInfoScreenWith(preset: InfoScreen.Preset) {
        let vc = InfoScreen.instantiate(preset: preset)
        if let nav = cNavigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = EmptyRootCNavigationController(rootViewController: vc)            
            nav.modalPresentationStyle = .overFullScreen
            present(nav, animated: true)
        }
    }
    
    func topVisibleViewController() -> UIViewController {
        var topController = self
        if topController is UITabBarController {
            return (topController as! UITabBarController).selectedViewController?.topVisibleViewController() ?? topController
        }
        
        if topController is UINavigationController {
            return (topController as! UINavigationController).topViewController?.topVisibleViewController() ?? topController
        }
        
        if topController is CNavigationController {
            return (topController as! CNavigationController).topViewController?.topVisibleViewController() ?? topController
        }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
            
            if topController is UINavigationController {
                topController = (topController as! UINavigationController).topViewController!
            }
        }
        
        return topController
    }
    
    func allChilds() -> [UIViewController] {
        var children = self.children
        for child in children {
            children.append(contentsOf: child.allChilds())
        }
        return children
    }
}

// MARK: - AuthenticationUIHandler
extension UIViewController: AuthenticationUIHandler {
    func showPasscodeViewController(_ passcodeViewController: UIViewController) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self]  in
            guard !(self is VerifyPasscodeViewController) else { return }
            
            self?.topVisibleViewController().present(passcodeViewController, animated: true)
        }
    }
    
    func showSecurityWallViewController(_ securityWallViewController: UIViewController) {
        guard !(self is SecurityWallViewController) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            self?.present(securityWallViewController, animated: true)
        }
    }
    
    func removeSecurityWallViewController() {
        DispatchQueue.main.async { [weak self]  in
            if let presentedViewController = self?.presentedViewController as? SecurityWallViewController {
                presentedViewController.dismiss(animated: false)
            } else if (self is SecurityWallViewController) {
                self?.dismiss(animated: false)
            }
        }
    }
}

// MARK: - External Links
extension UIViewController {
    func openLink(_ link: String.Links) {
        if let url = link.url {
            WebViewController.show(in: self, withURL: url)
        }
    }
    
    func showICloudDisabledAlert() {
        let viewName = (self as? BaseViewController)?.analyticsName ?? .unspecified
        let parameters: Analytics.EventParameters = [.viewName : viewName.rawValue]
        appContext.analyticsService.log(event: .iCloudDisabledAlertAppear, withParameters: parameters)
        let alert = UIAlertController(title: String.Constants.iCloudNotEnabledAlertTitle.localized(),
                                      message: String.Constants.iCloudNotEnabledAlertMessage.localized(),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: String.Constants.iCloudNotEnabledAlertConfirmButton.localized(),
                                      style: .default,
                                      handler: { [weak self] _ in
            self?.showICloudSetupTutorial()
            appContext.analyticsService.log(event: .iCloudDisabledAlertShowTutorialPressed, withParameters: parameters)
        }))
        alert.addAction(UIAlertAction(title: String.Constants.iCloudNotEnabledAlertDeclineButton.localized(), style: .cancel, handler: { _ in
            appContext.analyticsService.log(event: .iCloudDisabledAlertCancelPressed, withParameters: parameters)
        }))

        present(alert, animated: true)
    }
    
    func showICloudSetupTutorial() {
        openLink(.setupICloudDriveInstruction)
    }
    
    func openMailApp() {
        guard let url = URL(string: "message://") else { return }

        openURLExternally(url)
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

        openURLExternally(url)
    }
    
    func openUDTwitter() {
        let twitterName = Constants.UnstoppableTwitterName
        let appURL = URL(string: "twitter://user?screen_name=\(twitterName)")!
        let webURL = URL(string: "https://twitter.com/\(twitterName)")!
        
        if !openURLExternally(appURL) {
            openURLExternally(webURL)
        }
    }
    
    func openAppStore(for appId: String) {
        guard let url = URL(string: "itms-apps://apple.com/app/\(appId)") else { return }
        
        openURLExternally(url)
    }
    
    @discardableResult
    func openURLExternally(_ url: URL) -> Bool {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }
    
    
    func openLinkExternally(_ link: String.Links) {
        guard let url = link.url else { return }

        openURLExternally(url)
    }
    
    func shareDomainProfile(domainName: DomainName,
                            isUserDomain: Bool,
                            additionalItems: [Any] = []) {
        guard let url = String.Links.domainProfilePage(domainName: domainName).url else { return }

        let titleItem = DomainURLActivityItemSource(isUserDomain: isUserDomain, url: url, isTitleOnly: true)
        let linkItem = DomainURLActivityItemSource(isUserDomain: isUserDomain, url: url, isTitleOnly: false)
        let activityItems: [Any] = [titleItem, linkItem] + additionalItems
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                AppReviewService.shared.appReviewEventDidOccurs(event: .didShareProfile)
            }
        }
        present(activityViewController, animated: true)
    }
}
 
extension UIViewController {
    func dismissPullUpMenu(completion: EmptyCallback? = nil) {
        if let pullUpView = presentedViewController as? PullUpViewController {
            pullUpView.dismiss(animated: true, completion: completion)
        } else if let pullUpView = self as? PullUpViewController {
            pullUpView.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
    }
    
    @MainActor
    func dismissPullUpMenu() async {
        await withSafeCheckedMainActorContinuation { completion in
            self.dismissPullUpMenu {
                completion(Void())
            }
        }
    }
    
    @MainActor
    func dismiss(animated: Bool) async {
        await withSafeCheckedMainActorContinuation { completion in
            self.dismiss(animated: animated) {
                completion(Void())
            }
        }
    }
}

extension UIViewController {
    func childOf<T: UIViewController>(type: T.Type) -> T? {
        if let vc = self as? T {
            return vc
        }
        
        return presentedViewController?.childOf(type: type)
    }
}

import SafariServices

extension UIViewController {
    func openLinkInSafari(_ link: String.Links) {
        guard let url = link.url else { return }
        
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}
