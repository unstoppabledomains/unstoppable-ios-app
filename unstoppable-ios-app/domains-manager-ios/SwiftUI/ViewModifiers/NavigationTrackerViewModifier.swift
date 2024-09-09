//
//  NavigationTrackerViewModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.03.2024.
//

import SwiftUI

struct NavigationTrackerViewModifier: ViewModifier {
    
    var onDidNotFinishNavigationBack: EmptyCallback? = nil
    var onDidStartBackGesture: EmptyCallback? = nil
    var onDidBackGestureProgress: ((Double)->())? = nil
    @State private var didSetupHandler = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !didSetupHandler else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let topVC = appContext.coreAppCoordinator.topVC,
                       let nav = getNavigationController(from: topVC) {
                        UINavigationViewControllerTracker.shared.trackNavigationController(nav,
                                                                                           handler: self)
                        didSetupHandler = true
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

// MARK: - UINavigationControllerTrackerHandler
extension NavigationTrackerViewModifier: UINavigationControllerTrackerHandler {
    func didNotFinishNavigationBack() {
        onDidNotFinishNavigationBack?()
    }
    
    func didStartBackGesture() {
        onDidStartBackGesture?()
    }
    
    func didBackGestureProgress(_ progress: Double) {
        onDidBackGestureProgress?(progress)
    }
}

extension View {
    func trackNavigationControllerEvents(onDidNotFinishNavigationBack: EmptyCallback? = nil,
                                         onDidStartBackGesture: EmptyCallback? = nil,
                                         onDidBackGestureProgress: ((Double)->())? = nil) -> some View {
        modifier(NavigationTrackerViewModifier(onDidNotFinishNavigationBack: onDidNotFinishNavigationBack,
                                               onDidStartBackGesture: onDidStartBackGesture,
                                               onDidBackGestureProgress: onDidBackGestureProgress))
    }
}

protocol UINavigationControllerTrackerHandler {
    func didNotFinishNavigationBack()
    func didStartBackGesture()
    func didBackGestureProgress(_ progress: Double)
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
    
    @objc private func handleSwipeGesture(_ gesture: UIPanGestureRecognizer) {
        guard let gestureView = gesture.view else { return }
        
        let translation: CGPoint = gesture.translation(in: gestureView)
        let percentProgress: CGFloat = abs(translation.x / gestureView.bounds.size.width);
        
        for (holder, handlers) in navsToCallbacks {
            guard holder.nav?.interactivePopGestureRecognizer == gesture else { continue }
            
            switch gesture.state {
            case .began:
                handlers.forEach { $0.didStartBackGesture() }
                holder.nav?.transitionCoordinator?.notifyWhenInteractionChanges({ context in
                 
                    if context.completionVelocity < 0 { // will restore current view controller
                        handlers.forEach { $0.didNotFinishNavigationBack() }
                    }
                })
                return
            case .changed:
                handlers.forEach { $0.didBackGestureProgress(percentProgress) }
            default:
                return
            }
        }
    }
    
    private struct NavigationControllerHolder: Hashable {
        let id = UUID()
        weak var nav: UINavigationController?
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.id == rhs.id else { return false }
            guard lhs.nav == rhs.nav else { return false }
            
            return true
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(nav)
        }
    }
}
