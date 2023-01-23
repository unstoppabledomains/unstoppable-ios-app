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
    @IBOutlet private weak var stepDescriptionLabel: UDSubtitleLabel!
    @IBOutlet private weak var labelsStackView: UIStackView!

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
        stepNameLabel.setTitle(screenType.name)
        stepDescriptionLabel.setSubtitle(screenType.description)
        
        if deviceSize == .i4Inch {
            labelsStackView.spacing = 8
        }
    }
}

// MARK: - Setup
private extension TutorialStepViewController {
    func setup() { }
}
