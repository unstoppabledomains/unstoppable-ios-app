//
//  MessagingChatMessageImageDataTypeDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.07.2023.
//

import UIKit

struct MessagingChatMessageImageDataTypeDisplayInfo: Hashable {
    
    let data: Data
    let image: UIImage
    
}

// MARK: - Open methods
extension MessagingChatMessageImageDataTypeDisplayInfo {
    init?(data: Data) {
        guard let image = UIImage(data: data) else { return nil }
        self.data = data
        self.image = image
    }
}
