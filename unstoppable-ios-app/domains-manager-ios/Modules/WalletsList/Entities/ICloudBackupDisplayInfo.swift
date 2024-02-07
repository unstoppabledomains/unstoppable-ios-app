//
//  RestoreFromICloudBackupOption.swift.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 12.05.2022.
//

import UIKit

struct ICloudBackupDisplayInfo: Equatable {
    
    let date: Date
    let subtitleMessage: String
    let isCurrent: Bool
    
    init(date: Date, backedUpWallets: [BackedUpWallet], isCurrent: Bool) {
        self.date = date
        self.isCurrent = isCurrent
        
        let walletsCount = backedUpWallets.count
        subtitleMessage = String.Constants.pluralNWallets.localized(walletsCount, walletsCount)
    }
    
}

// MARK: - PullUpCollectionViewCellItem
extension ICloudBackupDisplayInfo: PullUpCollectionViewCellItem {
    var title: String {
        DateFormattingService.shared.formatICloudBackUpDate(date)
    }
    
    var subtitle: String? {
        if isCurrent {
            return subtitleMessage + " · " + String.Constants.current.localized()
        }
        return subtitleMessage
    }
    
    var subtitleColor: UIColor {
        isCurrent ? .foregroundAccent : .foregroundSecondary
    }
    
    var icon: UIImage {
        .cloudIcon
    }
    
    var tintColor: UIColor {
        isCurrent ? .foregroundOnEmphasis : .foregroundDefault
    }
    
    var backgroundColor: UIColor {
        isCurrent ? .backgroundAccentEmphasis : .backgroundMuted2
    }
    
    var analyticsName: String {
        "backUp"
    }
}
