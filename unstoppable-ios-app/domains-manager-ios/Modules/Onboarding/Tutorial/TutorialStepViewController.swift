//
//  TutorialStepViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

final class TutorialStepViewController: BaseViewController {
    
    @IBOutlet private weak var stepImageView: UIImageView!
    @IBOutlet private weak var stepNameLabel: UDTitleLabel!
    @IBOutlet private weak var labelsStackView: UIStackView!
    @IBOutlet private weak var contentTopConstraint: NSLayoutConstraint!

    override var analyticsName: Analytics.ViewName { .onboardingTutorialStep }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup() 
    }
    
}

// MARK: - Open methods
extension TutorialStepViewController {
    func configureWith(screenType: TutorialViewController.TutorialScreenType) {
        stepImageView.image = screenType.image
        let fontSize: CGFloat = deviceSize == .i4_7Inch ? 32 : 44
        contentTopConstraint.constant = deviceSize == .i4_7Inch ? 50 : 90
        stepNameLabel.setAttributedTextWith(text: screenType.name,
                                            font: .currentFont(withSize: fontSize, weight: .bold),
                                            textColor: .foregroundDefault)
        
        if deviceSize == .i4Inch {
            labelsStackView.spacing = 8
        }
    }
}

// MARK: - Setup
private extension TutorialStepViewController {
    func setup() { }
}
