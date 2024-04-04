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
    
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
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
