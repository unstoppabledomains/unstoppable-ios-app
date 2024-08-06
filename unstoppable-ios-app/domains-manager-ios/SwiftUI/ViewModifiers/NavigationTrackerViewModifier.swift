//
//  NavigationTrackerViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2024.
//

import SwiftUI

struct NavigationTrackerViewModifier: ViewModifier {
    
    var onDidNotFinishNavigationBack: EmptyCallback? = nil
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let topVC = appContext.coreAppCoordinator.topVC,
                       let nav = getNavigationController(from: topVC) {
                        UINavigationViewControllerTracker.shared.trackNavigationController(nav,
                                                                                           handler: self)
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

final class UINavigationViewControllerTracker: NSObject {
    
    static let shared = UINavigationViewControllerTracker()
    
    private var navsToCallbacks: [NavigationControllerHolder : [UINavigationControllerTrackerHandler]] = [:]
    
    func trackNavigationController(_ navigationController: UINavigationController?,
                                   handler: UINavigationControllerTrackerHandler) {
        let holder = NavigationControllerHolder(nav: navigationController)
        navsToCallbacks[holder, default: []].append(handler)
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(handleSwipeGesture))
    }
    
    @objc private func handleSwipeGesture(_ gesture: UIGestureRecognizer) {
        for (holder, handlers) in navsToCallbacks {
            guard holder.nav?.interactivePopGestureRecognizer == gesture else { continue }
            
            switch gesture.state {
            case .began:
                holder.nav?.transitionCoordinator?.notifyWhenInteractionChanges({ context in
                    if context.completionVelocity < 0 { // will restore current view controller
                        for handler in handlers {
                            handler.didNotFinishNavigationBack()
                        }
                    }
                })
                return
            default:
                return
            }
        }
    }
    
    private struct NavigationControllerHolder: Hashable {
        weak var nav: UINavigationController?
    }
}
