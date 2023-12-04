//
//  PreviewPullUpViewService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

protocol PullUpViewServiceProtocol {
    func showApplePayRequiredPullUp(in viewController: UIViewController)
}

final class PullUpViewService: PullUpViewServiceProtocol {
    func showApplePayRequiredPullUp(in viewController: UIViewController) { }
}


