//
//  ManageBackupsAction.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 03.05.2022.
//

import UIKit

enum ManageBackupsAction: String, CaseIterable, PullUpCollectionViewCellItem {
    
    case restore, delete
    
    var title: String {
        switch self {
        case .restore:
            return String.Constants.restoreFromICloudBackup.localized()
        case .delete:
            return String.Constants.deleteICloudBackups.localized()
        }
    }

    var titleColor: UIColor {
        switch self {
        case .restore: return .foregroundAccent
        case .delete: return .foregroundDanger
        }
    }
    
    var icon: UIImage {
        switch self {
        case .restore:
            return .cloudIcon
        case .delete:
            return UIImage(named: "stopIcon")!
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .restore: return .foregroundAccent
        case .delete: return .foregroundDanger
        }
    }
    
    var backgroundColor: UIColor { .clear }
    
    var imageSize: ResizableRoundedImageView.Size { .init(containerSize: 24, imageSize: 20) }
    var imageStyle: ResizableRoundedImageView.Style { .smallImage }
        
    var height: CGFloat { 54 }
    var analyticsName: String { rawValue }

}
