//
//  MainWindow.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.05.2022.
//

import UIKit

final class MainWindow: UIWindow {
    
    override var rootViewController: UIViewController? { didSet { checkToastView() } }
    
    func dismissActivityController() {
        if let activityVC = self.rootViewController?.childOf(type: UIActivityViewController.self) {
            activityVC.presentingViewController?.dismiss(animated: true)
        }
    }
}

// MARK: - Private methods
private extension MainWindow {
    func checkToastView() {
        if let toastView = self.firstSubviewOfType(ToastView.self) {
            bringSubviewToFront(toastView)
        }
    }
}
