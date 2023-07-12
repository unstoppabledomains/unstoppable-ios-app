//
//  MessagingChatUserPullUpSelectionItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.07.2023.
//

import UIKit

struct MessagingChatUserPullUpSelectionItem: PullUpCollectionViewCellItem {
    let userInfo: MessagingChatUserDisplayInfo
    let isPending: Bool
    
    var title: String { userInfo.displayName }
    var subtitle: String? { isPending ? String.Constants.pending.localized() : nil }
    var imageStyle: ResizableRoundedImageView.Style { .largeImage }
    var icon: UIImage {
        get async {
            let placeholder = UIImage.domainSharePlaceholder
            if let pfpURL = userInfo.pfpURL {
                return await appContext.imageLoadingService.loadImage(from: .url(pfpURL),
                                                                      downsampleDescription: nil) ?? placeholder
            }
            return placeholder
        }
    }
    
    var analyticsName: String { "groupChatUser" }
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { userInfo.domainName == nil ? .none : .right }
    var isSelectable: Bool { userInfo.domainName != nil }
    
    
}
