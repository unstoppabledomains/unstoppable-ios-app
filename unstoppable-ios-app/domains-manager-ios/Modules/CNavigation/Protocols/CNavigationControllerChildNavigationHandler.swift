//
//  CNavigationControllerChildNavigationHandler.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.08.2022.
//

import Foundation

protocol CNavigationControllerChildNavigationHandler {
    func cNavigationChildWillBeDismissed()
    func cNavigationChildDidDismissed()
}

extension CNavigationControllerChildNavigationHandler {
    func cNavigationChildWillBeDismissed() { }
    func cNavigationChildDidDismissed() { }
}
