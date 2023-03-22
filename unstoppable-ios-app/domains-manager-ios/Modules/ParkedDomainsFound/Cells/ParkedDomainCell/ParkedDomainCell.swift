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
        
    }
}

// MARK: - Private methods
private extension FirebaseDomainDisplayInfo {
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
    
    func subtitleParkingStatus(_ parkingStatus: DomainParkingStatus) -> String? {
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
