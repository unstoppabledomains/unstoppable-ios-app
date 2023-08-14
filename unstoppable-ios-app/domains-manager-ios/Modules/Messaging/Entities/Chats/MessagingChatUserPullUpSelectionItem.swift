//
//  MessagingChatUserPullUpSelectionItem.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.07.2023.
//

import UIKit

struct MessagingChatUserPullUpSelectionItem: PullUpCollectionViewCellItem {
    let userInfo: MessagingChatUserDisplayInfo
    let isAdmin: Bool
    let isPending: Bool
    
    var title: String { userInfo.displayName }
    var subtitle: String? {
        if isPending { return String.Constants.pending.localized() }
        if isAdmin { return String.Constants.messagingAdmin.localized() }
        return nil
    }
    var imageStyle: ResizableRoundedImageView.Style { .largeImage }
    var icon: UIImage {
        get async {
            if let pfpURL = userInfo.pfpURL,
               let avatar = await appContext.imageLoadingService.loadImage(from: .url(pfpURL),
                                                                           downsampleDescription: nil) {
                return avatar
            } else if let initialsImage = await appContext.imageLoadingService.loadImage(from: .initials(userInfo.domainName ?? userInfo.wallet.droppedHexPrefix,
                                                                                                         size: .default,
                                                                                                         style: .accent),
                                                                                         downsampleDescription: nil) {
                return initialsImage
            }
            
            return UIImage.domainSharePlaceholder
        }
    }
    
    var analyticsName: String { "groupChatUser" }
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { userInfo.domainName == nil ? .none : .right }
    var isSelectable: Bool { userInfo.domainName != nil }
    
    
}
