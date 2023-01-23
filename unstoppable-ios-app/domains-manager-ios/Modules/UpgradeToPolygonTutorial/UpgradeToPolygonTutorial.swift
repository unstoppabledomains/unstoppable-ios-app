//
//  UpgradeToPolygon.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.06.2022.
//

import UIKit

final class UpgradeToPolygonTutorial: BaseViewController {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var gradientView: UDGradientCoverView!
    @IBOutlet private weak var goToWebButton: MainButton!
    @IBOutlet private weak var stepOneLabel: UILabel!
    @IBOutlet private weak var stepTwoLabel: UILabel!
    @IBOutlet private weak var stepThreeLabel: UILabel!
    @IBOutlet private weak var stepFourLabel: UILabel!

    override var navBackStyle: BaseViewController.NavBackIconStyle { .cancel }
    override var analyticsName: Analytics.ViewName { .upgradeToPolygonTutorial }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

}

// MARK: - Private functions
private extension UpgradeToPolygonTutorial {
    @IBAction func goToWebButtonPressed() {
        logButtonPressedAnalyticEvents(button: .goToWebsite)
        openLink(.upgradeToPolygon)
    }
}

// MARK: - Setup functions
private extension UpgradeToPolygonTutorial {
    func setup() {
        localizeContent()
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.freeUpgradeToPolygon.localized())
        subtitleLabel.setSubtitle(String.Constants.freeUpgradeToPolygonSubtitle.localized())
        setText(String.Constants.upgradeZilToPolygonStep1.localized(), toStepLabel: stepOneLabel)
        setText(String.Constants.upgradeZilToPolygonStep2.localized(), toStepLabel: stepTwoLabel)
        setText(String.Constants.upgradeZilToPolygonStep3.localized(), toStepLabel: stepThreeLabel)
        setText(String.Constants.upgradeZilToPolygonStep4.localized(), toStepLabel: stepFourLabel)
        goToWebButton.setTitle(String.Constants.goToWebsite.localized(), image: nil)
    }
    
    func setText(_ text: String, toStepLabel stepLabel: UILabel) {
        stepLabel.setAttributedTextWith(text: text,
                                        font: .currentFont(withSize: 16, weight: .medium),
                                        textColor: .foregroundDefault)
        
    }
}
