//
//  DomainProfileSectionChangeUIDescription.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit

protocol DomainProfileSectionChangeUIDescription: PullUpCollectionViewCellItem, Hashable {
    var title: String { get }
    var icon: UIImage { get async }
    var backgroundColor: UIColor { get }
    var imageStyle: ResizableRoundedImageView.Style { get }
}

extension DomainProfileSectionChangeUIDescription {
    var backgroundColor: UIColor { .backgroundMuted2 }
    var imageStyle: ResizableRoundedImageView.Style { .imageCentered }
}
