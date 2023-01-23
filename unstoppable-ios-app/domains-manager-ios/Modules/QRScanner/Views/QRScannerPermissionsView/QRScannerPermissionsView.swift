//
//  QRScannerPermissionsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2022.
//

import Foundation
import UIKit

final class QRScannerPermissionsView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet private var scanToPayLabel: UILabel!
    @IBOutlet private var cameraDeniedLabel: UILabel!
    @IBOutlet private var enabledCameraButton: TextButton!

    var enableCameraButtonPressedCallback: EmptyCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func setCameraNotAvailable() {
        enabledCameraButton.isHidden = true
        cameraDeniedLabel.isHidden = false
        cameraDeniedLabel.setAttributedTextWith(text: String.Constants.cameraNotAvailable.localized(),
                                                font: .currentFont(withSize: 16, weight: .regular),
                                                textColor: .foregroundDanger)
    }
}

// MARK: - Actions
private extension QRScannerPermissionsView {
    @IBAction func enableCameraButtonPressed() {
        enableCameraButtonPressedCallback?()
    }
}

// MARK: - Setup methods
private extension QRScannerPermissionsView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        cameraDeniedLabel.isHidden = true
        
        scanToPayLabel.setAttributedTextWith(text: String.Constants.scanToPayOrConnect.localized(),
                                             font: .currentFont(withSize: 22, weight: .bold),
                                             textColor: .foregroundOnEmphasis)
        cameraDeniedLabel.setAttributedTextWith(text: String.Constants.cameraAccessNeededToScan.localized(),
                                                font: .currentFont(withSize: 16, weight: .regular),
                                                textColor: .foregroundOnEmphasisOpacity)
        enabledCameraButton.setTitle(String.Constants.enableCameraAccess.localized(), image: .magicWandIcon)
    }
}

