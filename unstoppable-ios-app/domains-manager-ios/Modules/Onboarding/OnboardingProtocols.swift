//
//  OnboardingProtocols.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.04.2022.
//

import Foundation
import UIKit

protocol OnboardingFlowManager: AnyObject {
    var onboardingFlow: OnboardingNavigationController.OnboardingFlow { get }
    var onboardingData: OnboardingData { get set }
    
    func moveToStep(_ step: OnboardingNavigationController.OnboardingStep)
    func setNewUserOnboardingSubFlow(_ onboardingSubFlow: OnboardingNavigationController.NewUserOnboardingSubFlow?)
    func didSetupProtectWallet()
    func didFinishOnboarding()
    func modifyOnboardingData(modifyingBlock: (inout OnboardingData) -> Void)
}

protocol OnboardingNavigationHandler {
    var onboardingStep: OnboardingNavigationController.OnboardingStep { get }
    var viewController: UIViewController? { get }
}

protocol OnboardingDataHandling: AnyObject {
    func willNavigateBack()
}

extension OnboardingDataHandling {
    // will be implemented customly per specific VC
    func willNavigateBack() { }
}
