//
//  NavigationTrackerViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2024.
//

import SwiftUI

struct NavigationTrackerViewModifier: ViewModifier {
    
    var onDidNotFinishNavigationBack: EmptyCallback? = nil
    @StateObject private var navigationTracker = UINavigationViewControllerTracker()
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let topVC = appContext.coreAppCoordinator.topVC,
                       let nav = getNavigationController(from: topVC) {
                        navigationTracker.handler = self
                        navigationTracker.trackNavigationController(nav)
                    }
                }
            }
    }
    
    private func getNavigationController(from topVC: UIViewController) -> UINavigationController? {
        if let nav = topVC.children.first as? UINavigationController {
            return nav
        } else if let tabBarVC = topVC.children.first as? UITabBarController,
                  let selectedVC = tabBarVC.selectedViewController {
            return getNavigationController(from: selectedVC)
        }
        return nil
    }
    
}

extension NavigationTrackerViewModifier: UINavigationControllerTrackerHandler {
    func didNotFinishNavigationBack() {
        onDidNotFinishNavigationBack?()
    }
}

extension View {
    func trackNavigationControllerEvents(onDidNotFinishNavigationBack: EmptyCallback? = nil) -> some View {
        modifier(NavigationTrackerViewModifier(onDidNotFinishNavigationBack: onDidNotFinishNavigationBack))
    }
}

protocol UINavigationControllerTrackerHandler {
    func didNotFinishNavigationBack()
}

final class UINavigationViewControllerTracker: NSObject, ObservableObject, UINavigationControllerDelegate {
    var handler: UINavigationControllerTrackerHandler?
    
    func trackNavigationController(_ navigationController: UINavigationController?) {
        guard navigationController?.delegate !== self else { return }
        
        navigationController?.transitionCoordinator?.notifyWhenInteractionChanges({ [weak self] context in
            if context.completionVelocity < 0 { // will restore current view controller
                self?.handler?.didNotFinishNavigationBack()
            }
        })
    }
}
