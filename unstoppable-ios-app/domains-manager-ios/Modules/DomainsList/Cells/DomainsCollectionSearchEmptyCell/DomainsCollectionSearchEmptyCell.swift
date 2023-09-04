//
//  DomainsCollectionSearchEmptyCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.07.2022.
//

import UIKit

final class DomainsCollectionSearchEmptyCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var centerYConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        isUserInteractionEnabled = false
        setMode(.searchStarted)
        switch deviceSize {
        case .i4Inch:
            setCenterYOffset(60)
        case .i4_7Inch:
            setCenterYOffset(60)
        default:
            setCenterYOffset(150)
        }
    }

}

// MARK: - Open methods
extension DomainsCollectionSearchEmptyCell {
    func setCenterYOffset(_ offset: CGFloat) {
        centerYConstraint.constant = offset
    }
    
    func setMode(_ mode: Mode) {
        titleLabel.setAttributedTextWith(text: mode.title,
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundSecondary)
        hintLabel.setAttributedTextWith(text: mode.subtitle ?? "",
                                        font: .currentFont(withSize: 16, weight: .regular),
                                        textColor: .foregroundSecondary)
        hintLabel.isHidden = mode.subtitle == nil
    }
}

extension DomainsCollectionSearchEmptyCell {
    enum Mode {
        case searchStarted, noResults
        
        var title: String {
            switch self {
            case .searchStarted:
                return String.Constants.searchDomainsTitle.localized()
            case .noResults:
                return String.Constants.noResults.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .searchStarted:
                return String.Constants.searchDomainsTitle.localized()
            case .noResults:
                return nil
            }
        }
    }
}
