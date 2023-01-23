//
//  DomainsCollectionCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

final class DomainsCollectionCardCell: UICollectionViewCell {

    @IBOutlet private weak var udCardView: UDDomainCardView!
    @IBOutlet private weak var statusMessage: StatusMessage!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setup()
    }

}

// MARK: - Open methods
extension DomainsCollectionCardCell {
    func setWith(displayInfo: DomainsCollectionViewController.Item.DomainCardDisplayInfo) {
        let domainItem = displayInfo.domainItem
        accessibilityIdentifier = "Domains Collection Cell \(domainItem.name)"
        udCardView.setWith(domainItem: domainItem)
        statusMessage.isHidden = false
        switch domainItem.usageType {
        case .zil:
            statusMessage.setComponent(.bridgeDomainToPolygon)
        case .deprecated(let tld):
            statusMessage.setComponent(.deprecated(tld: tld))
        case .normal:
            if displayInfo.isUpdatingRecords {
                statusMessage.setComponent(.updatingRecords)
            } else {
                if !displayInfo.didTapPrimaryDomain {
                    statusMessage.setComponent(.tapOnCardToSeeDetails)
                } else {
                    statusMessage.isHidden = true
                }
            }
        }
    }
}

// MARK: - Setup methods
private extension DomainsCollectionCardCell {
    func setup() {
       addParallaxToView(view: udCardView)
    }
    
    func addParallaxToView(view: UIView) {
        var identity = CATransform3DIdentity
        view.layer.transform = identity
        identity.m34 = -1 / 500.0
        let angle: CGFloat = 5
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongVerticalAxis)
        vertical.maximumRelativeValue = CATransform3DRotate(identity, ((360 - angle) * .pi) / 180.0, 1.0, 0.0, 0.0)
        vertical.minimumRelativeValue = CATransform3DRotate(identity, (angle * .pi) / 180.0, 1.0, 0.0, 0.0)
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongHorizontalAxis)
        horizontal.maximumRelativeValue = CATransform3DRotate(identity, ((360 - angle) * .pi) / 180.0, 0.0, 1.0, 0.0)
        horizontal.minimumRelativeValue = CATransform3DRotate(identity, (angle * .pi) / 180.0, 0.0, 1.0, 0.0)
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        view.addMotionEffect(group)
    }
}
