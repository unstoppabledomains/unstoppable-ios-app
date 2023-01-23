//
//  DomainProfileSectionUIChangeFailedItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 15.11.2022.
//

import UIKit

struct DomainProfileSectionUIChangeFailedItem: PullUpCollectionViewCellItem {
    let failedChangeType: DomainProfileSectionUIChangeType
    
    var title: String { failedChangeType.title }
    var icon: UIImage { get async { await failedChangeType.icon } }
    
    var subtitle: String? { String.Constants.failed.localized() }
    var subtitleIcon: UIImage? { .cancelCircleIcon }
    var subtitleColor: UIColor { .foregroundSecondary }
    
    var backgroundColor: UIColor { failedChangeType.backgroundColor }
    var imageStyle: ResizableRoundedImageView.Style { failedChangeType.imageStyle }
    
    var isSelectable: Bool { false }
    var analyticsName: String { "" } // Not selectable
}
