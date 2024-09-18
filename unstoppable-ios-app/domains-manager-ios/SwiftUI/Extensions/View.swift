//
//  View.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 22.08.2023.
//

import SwiftUI
import Combine

@MainActor
extension View {
    var safeAreaInset: UIEdgeInsets {
        SceneDelegate.shared?.window?.safeAreaInsets ?? .zero
    }
    
    @inlinable
    public func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
    
    func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
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
    
    func openLink(_ link: String.Links) {
        guard let topVC = appContext.coreAppCoordinator.topVC else { return }
        
        topVC.openLink(link)
    }
    
    func openUDTwitter() {
        let twitterName = Constants.UnstoppableTwitterName
        let appURL = URL(string: "twitter://user?screen_name=\(twitterName)")!
        let webURL = URL(string: "https://twitter.com/\(twitterName)")!
        
        if !openURLExternally(appURL) {
            openURLExternally(webURL)
        }
    }
    
    func openMailApp() {
        guard let url = URL(string: "message://") else { return }
        
        openURLExternally(url)
    }
    
    func shareItems(_ items: [Any], completion: ((Bool)->())?) {
        guard let topVC = appContext.coreAppCoordinator.topVC else { return }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            completion?(completed)
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            let thisViewVC = UIHostingController(rootView: self)
            activityVC.popoverPresentationController?.sourceView = thisViewVC.view
        }
        
        topVC.present(activityVC, animated: true, completion: nil)
    }
    
    func findFirstUIViewOfType<T: UIView>(_ type: T.Type) -> T? {
        appContext.coreAppCoordinator.topVC?.view.firstSubviewOfType(type)
    }
    
    func findAllUIViewsOfType<T: UIView>(_ type: T.Type) -> [T] {
        appContext.coreAppCoordinator.topVC?.view.allSubviewsOfType(type) ?? []
    }
    
    var screenSize: CGSize { UIScreen.main.bounds.size }
    var isIPSE: Bool { deviceSize == .i4_7Inch }
}

extension View {
    func withoutAnimation() -> some View {
        self.transaction { transaction in
            transaction.animation = nil
        }
    }
}

extension ViewModifier {
    var screenSize: CGSize { UIScreen.main.bounds.size }
}

import MessageUI

extension View {
    func openEmailFormWith(recipientMailAddress: String,
                           subject: String) {
        let canSendMail = MFMailComposeViewController.canSendMail()
        if canSendMail {
            let mail = MFMailComposeViewController()
            mail.setToRecipients([recipientMailAddress])
            mail.setSubject(subject)
            
            Task { @MainActor in
                appContext.coreAppCoordinator.topVC?.present(mail, animated: true)
            }
        } else {
            let mailURLString = "mailto:\(recipientMailAddress)?subject=\(subject)"
            guard let url = URL(string: mailURLString) else { return }
            
            UIApplication.shared.open(url)
        }
    }
}
