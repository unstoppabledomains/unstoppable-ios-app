//
//  CNavigationControllerChild.swift
//  CustomNavigation
//
//  Created by Oleg Kuplin on 05.08.2022.
//

import Foundation
import UIKit

protocol CNavigationControllerChild: AnyObject {
    var navBarTitleAttributes: [NSAttributedString.Key : Any]? { get }
    
    var prefersLargeTitles: Bool { get }
    var largeTitleConfiguration: CNavigationBar.LargeTitleConfiguration? { get }
    
    var isNavBarHidden: Bool { get }
    var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration { get }
    var navBarDividerColor: UIColor { get }
    var scrollableContentYOffset: CGFloat? { get }
    func shouldPopOnBackButton() -> Bool
    func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())?
}

extension CNavigationControllerChild {
    var navBarTitleAttributes: [NSAttributedString.Key : Any]? { nil }
    
    var prefersLargeTitles: Bool { false }
    var largeTitleConfiguration: CNavigationBar.LargeTitleConfiguration? { nil }
    
    var isNavBarHidden: Bool { false }
    var navBackButtonConfiguration: CNavigationBarContentView.BackButtonConfiguration { .default }
    var navBarDividerColor: UIColor { .systemGray6 }
    var scrollableContentYOffset: CGFloat? { nil }
    func shouldPopOnBackButton() -> Bool { true }
    func customScrollingBehaviour(yOffset: CGFloat, in navBar: CNavigationBar) -> (()->())? { nil }
}
