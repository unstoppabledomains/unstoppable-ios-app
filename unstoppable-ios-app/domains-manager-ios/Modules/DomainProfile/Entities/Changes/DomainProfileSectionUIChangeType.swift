//
//  DomainProfileSectionChangeType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit

enum DomainProfileSectionUIChangeType {
    case added(_ item: DomainProfileSectionChangeUIDescription), removed(_ item: DomainProfileSectionChangeUIDescription), updated(_ item: DomainProfileSectionChangeUIDescription)
    case moreChanges(_ num: Int)
}

// MARK: - PullUpCollectionViewCellItem
extension DomainProfileSectionUIChangeType: PullUpCollectionViewCellItem {
    var title: String {
        switch self {
        case .added(let item), .removed(let item), .updated(let item):
            return item.title
        case .moreChanges(let num):
            return String.Constants.nUpdates.localized("+\(num)")
        }
    }
    var icon: UIImage {
        get async {
            switch self {
            case .added(let item), .removed(let item), .updated(let item):
                return await item.icon
            case .moreChanges:
                return .dotsIcon
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
        case .moreChanges:
            return nil
        }
    }
    
    var subtitleColor: UIColor {
        switch self {
        case .added:
            return .foregroundSuccess
        case .removed:
            return .foregroundDanger
        case .updated, .moreChanges:
            return .foregroundSecondary
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .added(let item), .removed(let item), .updated(let item):
            return item.backgroundColor
        case .moreChanges:
            return .backgroundMuted2
        }
    }
    
    var imageStyle: ResizableRoundedImageView.Style {
        switch self {
        case .added(let item), .removed(let item), .updated(let item):
            return item.imageStyle
        case .moreChanges:
            return .imageCentered
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
        case .moreChanges:
            return nil
        }
    }
    
    var isSelectable: Bool { false }
    var analyticsName: String { "" } // Not selectable
}
