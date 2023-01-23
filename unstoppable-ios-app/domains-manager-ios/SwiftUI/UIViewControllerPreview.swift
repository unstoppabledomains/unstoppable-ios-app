//
//  UIViewControllerPreview.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.10.2022.
//

import UIKit
import SwiftUI

struct UIViewControllerPreview: UIViewControllerRepresentable {
    let viewControllerBuilder: () -> UIViewController
    
    init(_ viewControllerBuilder: @escaping () -> UIViewController) {
        self.viewControllerBuilder = viewControllerBuilder
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        return viewControllerBuilder()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Not needed
    }
    
}
