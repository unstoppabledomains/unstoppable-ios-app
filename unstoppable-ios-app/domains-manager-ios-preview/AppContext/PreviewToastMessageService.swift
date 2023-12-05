//
//  PreviewToastMessageService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

@MainActor
protocol ToastMessageServiceProtocol {
    func showToast(_ toast: Toast, isSticky: Bool)
    func removeStickyToast(_ toast: Toast)
    func showToast(_ toast: Toast,
                   in view: UIView,
                   at position: Toast.Position?,
                   isSticky: Bool,
                   dismissDelay: TimeInterval?,
                   action: EmptyCallback?)
    func removeToast(from view: UIView)
}

final class ToastMessageService: ToastMessageServiceProtocol {
    
    nonisolated init() { }
    
    func showToast(_ toast: Toast, isSticky: Bool) {
        
    }
    
    func removeStickyToast(_ toast: Toast) {
        
    }
    
    func showToast(_ toast: Toast, in view: UIView, at position: Toast.Position?, isSticky: Bool, dismissDelay: TimeInterval?, action: EmptyCallback?) {
        
    }
    
    func removeToast(from view: UIView) {
        
    }
    
    
}

