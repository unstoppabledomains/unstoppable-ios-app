//
//  WatchFaceDomainImagePreviewView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.06.2022.
//

import Foundation
import UIKit

final class WatchFaceDomainImagePreviewView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var domainSharingCardView: UDDomainSharingWatchCardView!
    @IBOutlet private weak var topGradientView: GradientView!
    @IBOutlet private weak var bottomGradientView: GradientView!

    private var saveDomainImageDescription: SaveDomainImageDescription?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

// MARK: - SaveDomainImagePreviewProvider
extension WatchFaceDomainImagePreviewView: SaveDomainImagePreviewProvider {
    var title: String { String.Constants.watchface.localized() }
    
    func setPreview(with saveDomainImageDescription: SaveDomainImageDescription) {
        self.saveDomainImageDescription = saveDomainImageDescription
        timeLabel.setAttributedTextWith(text: time,
                                        font: .currentFont(withSize: 10, weight: .regular),
                                        textColor: .white)
        domainSharingCardView.setWith(domain: saveDomainImageDescription.domain,
                                      qrImage: saveDomainImageDescription.qrImage)
    }
    
    func finalImage() -> UIImage? {
        guard let saveDomainImageDescription = self.saveDomainImageDescription else { return nil }
        
        let watchSharingCard = UDDomainSharingWatchCardView(frame: CGRect(x: 0, y: 0, width: 198, height: 242))
        watchSharingCard.overrideUserInterfaceStyle = UserDefaults.appearanceStyle
        watchSharingCard.setNeedsLayout()
        watchSharingCard.layoutIfNeeded()
        watchSharingCard.setWith(domain: saveDomainImageDescription.domain,
                                 avatarImage: saveDomainImageDescription.originalDomainImage,
                                 qrImage: saveDomainImageDescription.qrImage)
        watchSharingCard.prepareForExport()
                
        return watchSharingCard.renderedImage()
    }
}

// MARK: - Setup methods
private extension WatchFaceDomainImagePreviewView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        topGradientView.gradientColors = [.backgroundDefault, .backgroundDefault.withAlphaComponent(0.01)]
        bottomGradientView.gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault]
    }
}

