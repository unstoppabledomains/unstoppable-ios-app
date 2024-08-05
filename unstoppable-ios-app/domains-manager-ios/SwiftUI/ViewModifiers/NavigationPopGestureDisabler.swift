//
//  NavigationPopGestureDisabler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.08.2024.
//

import SwiftUI

extension UIView {
    var parentViewController: UIViewController? {
        sequence(first: self) {
            $0.next
        }.first { $0 is UIViewController } as? UIViewController
    }
}

private struct NavigationPopGestureDisabler: UIViewRepresentable {
    let disabled: Bool
    
    func makeUIView(context: Context) -> some UIView { UIView() }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            uiView
                .parentViewController?
                .navigationController?
                .interactivePopGestureRecognizer?.isEnabled = !disabled
        }
    }
}
public extension View {
    @ViewBuilder
    func navigationPopGestureDisabled(_ disabled: Bool) -> some View {
        background {
            NavigationPopGestureDisabler(disabled: disabled)
        }
        //        .navigationBarBackButtonHidden(disabled)
    }
}
