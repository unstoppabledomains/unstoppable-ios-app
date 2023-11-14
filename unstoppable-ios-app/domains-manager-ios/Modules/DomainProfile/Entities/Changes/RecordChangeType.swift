//
//  RecordChangeType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.05.2022.
//

import UIKit

enum RecordChangeType {
    case added(_ record: CryptoRecord), removed(_ record: CryptoRecord), updated(_ record: CryptoRecord)
}

// MARK: - PullUpCollectionViewCellItem
extension RecordChangeType: PullUpCollectionViewCellItem, DomainProfileSectionChangeUIDescription {
    var title: String {
        switch self {
        case .added(let record), .removed(let record), .updated(let record):
            return "\(record.coin.ticker ): \(record.address.walletAddressTruncated)"
        }
    }
    var icon: UIImage {
        get async {
            switch self {
            case .added(let record), .removed(let record), .updated(let record):
                return await appContext.imageLoadingService.loadImage(from: .currency(record.coin,
                                                                                      size: .default,
                                                                                      style: .gray),
                                                                      downsampleDescription: .icon) ?? .init()
            }
        }
    }
    
    var subtitle: String? {
        switch self {
        case .added:
            return String.Constants.added.localized()
        case .removed:
            return String.Constants.removed.localized()
        case .updated:
            return String.Constants.updated.localized()
        }
    }
    
    var subtitleColor: UIColor {
        switch self {
        case .added:
            return .foregroundSuccess
        case .removed:
            return .foregroundDanger
        case .updated:
            return .foregroundSecondary
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .added, .removed, .updated:
            return .clear
        }
    }
    
    var imageStyle: ResizableRoundedImageView.Style {
        switch self {
        case .added, .removed, .updated:
            return .largeImage
        }
    }
    
    var subtitleIcon: UIImage? {
        switch self {
        case .added:
            return .plusCircle
        case .removed:
            return .minusCircle
        case .updated:
            return .refreshIcon
        }
    }
    
    var isSelectable: Bool { false }
    var analyticsName: String { "" } // Not selectable
}
