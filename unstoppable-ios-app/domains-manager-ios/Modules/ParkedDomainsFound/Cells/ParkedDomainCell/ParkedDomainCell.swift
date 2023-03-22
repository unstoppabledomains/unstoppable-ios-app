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
              let status = statusForParkingStatus(parkingStatus) else {
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
        case .freeParking:
            return .parkingIcon24
        case .parked:
            return .warningIcon
        case .waitingForParkingOrClaim:
            return .warningIcon
        }
    }
    
    func iconTintColorForParkingStatus(_ parkingStatus: DomainParkingStatus) -> UIColor? {
        switch parkingStatus {
        case .claimed:
            return nil
        case .freeParking:
            return .foregroundSecondary
        case .parked:
            return .foregroundWarning
        case .waitingForParkingOrClaim:
            return .foregroundWarning
        }
    }
    
    func statusForParkingStatus(_ parkingStatus: DomainParkingStatus) -> String? {
        switch parkingStatus {
        case .claimed:
            return nil
        case .freeParking:
            return String.Constants.parked.localized()
        case .parked(let expiresDate):
            let formattedDate = DateFormattingService.shared.formatParkingExpiresDate(expiresDate)
            return String.Constants.parkingExpiresOn.localized(formattedDate)
        case .waitingForParkingOrClaim:
            return String.Constants.parked.localized()
        }
    }
}
