//
//  MessagingChatMessageImageTypeDisplayInfo.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.06.2023.
//

import UIKit

struct MessagingChatMessageImageBase64TypeDisplayInfo: Hashable {
  
    let base64: String
    let encryptedContent: String
    let base64Image: String // Make constant due to performance issues
    var image: UIImage?
    
    init(base64: String, encryptedContent: String, image: UIImage? = nil) {
        self.base64 = base64
        self.encryptedContent = encryptedContent
        self.base64Image = Base64DataTransformer.removeDataHeaderFrom(string: base64)
    }
    
}
