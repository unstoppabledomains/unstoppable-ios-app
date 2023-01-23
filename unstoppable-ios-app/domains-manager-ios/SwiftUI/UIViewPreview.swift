//
//  UIViewPreview.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.10.2022.
//

import UIKit
import SwiftUI

struct UIViewPreview: UIViewRepresentable {
    
    let viewBuilder: () -> UIView
    
    init(_ viewControllerBuilder: @escaping () -> UIView) {
        self.viewBuilder = viewControllerBuilder
    }
    
    func makeUIView(context: Self.Context) -> some UIView {
        return viewBuilder()
    }
    
    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) {
        
    }
    
}
