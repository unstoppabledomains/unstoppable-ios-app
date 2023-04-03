//
//  ParkedDomainCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.03.2023.
//

import UIKit

final class ParkedDomainCell: BaseListCollectionViewCell {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var statusIcon: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

// MARK: - Open methods
extension ParkedDomainCell {
    func setWith(domain: FirebaseDomainDisplayInfo) {
        setDomainName(domain.name)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .initials(domain.name,
                                                                                       size: .default,
                                                                                       style: .accent),
                                                                       downsampleDescription: nil)
            imageView.image = image
        }

        let parkingStatus = domain.parkingStatus
        guard let icon = iconForParkingStatus(parkingStatus),
              let iconTint = iconTintColorForParkingStatus(parkingStatus),
              let status = parkingStatus.title else {
            Debugger.printFailure("Failed to get required information for parking domain", critical: true)
            setStatus("", icon: nil, tintColor: .foregroundSecondary)
            return
        }
        
        setStatus(status, icon: icon, tintColor: iconTint)
    }
}

// MARK: - Private methods
private extension ParkedDomainCell {
    func setDomainName(_ name: String) {
        nameLabel.setAttributedTextWith(text: name,
                                        font: .currentFont(withSize: 16, weight: .medium),
                                        textColor: .foregroundDefault,
                                        lineBreakMode: .byTruncatingTail)
    }
    
    func setStatus(_ status: String, icon: UIImage?, tintColor: UIColor) {
        statusLabel.setAttributedTextWith(text: status,
                                        font: .currentFont(withSize: 14, weight: .medium),
                                        textColor: tintColor,
                                        lineBreakMode: .byTruncatingTail)

        statusIcon.image = icon
        statusIcon.tintColor = tintColor
    }
    
    
    func iconForParkingStatus(_ parkingStatus: DomainParkingStatus) -> UIImage? {
        switch parkingStatus {
        case .claimed:
            return nil
        case .freeParking, .parked, .parkingTrial, .parkingExpired, .parkedButExpiresSoon:
            return .parkingIcon24
        }
    }
    
    func iconTintColorForParkingStatus(_ parkingStatus: DomainParkingStatus) -> UIColor? {
        switch parkingStatus {
        case .claimed:
            return nil
        case .freeParking, .parked:
            return .foregroundSecondary
        case .parkedButExpiresSoon, .parkingTrial:
            return .foregroundWarning
        case .parkingExpired:
            return .foregroundDanger
        }
    }
}
