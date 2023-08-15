//
//  DomainProfileSectionChangeType.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit

enum DomainProfileSectionUIChangeType: Hashable {
 
    case added(_ item: any DomainProfileSectionChangeUIDescription), removed(_ item: any DomainProfileSectionChangeUIDescription), updated(_ item: any DomainProfileSectionChangeUIDescription)
    case moreChanges(_ num: Int)
    
    static func == (lhs: DomainProfileSectionUIChangeType, rhs: DomainProfileSectionUIChangeType) -> Bool {
        switch (lhs, rhs) {
        case (.added(let lhsItem), .added(let rhsItem)):
            return lhsItem.isEqual(rhsItem)
        case (.removed(let lhsItem), .removed(let rhsItem)):
            return lhsItem.isEqual(rhsItem)
        case (.updated(let lhsItem), .updated(let rhsItem)):
            return lhsItem.isEqual(rhsItem)
        case (.moreChanges(let lhsNum), .moreChanges(let rhsNum)):
            return lhsNum == rhsNum
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .added(let item):
            hasher.combine(0)
            hasher.combine(item)
        case .removed(let item):
            hasher.combine(1)
            hasher.combine(item)
        case .updated(let item):
            hasher.combine(2)
            hasher.combine(item)
        case .moreChanges(let item):
            hasher.combine(3)
            hasher.combine(item)
        }
    }
    
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
