//
//  DomainURLActivityItemSource.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.05.2022.
//

import Foundation
import LinkPresentation

final class DomainURLActivityItemSource: NSObject, UIActivityItemSource {
    
    var title: String
    var url: URL
    var isTitleOnly: Bool
    
    init(title: String? = nil , url: URL, isTitleOnly: Bool) {
        let title = title ?? String.Constants.domainDetailsShareMessage.localized()
        self.title = title
        self.url = url
        self.isTitleOnly = isTitleOnly
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any { isTitleOnly ? title : url }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? { isTitleOnly ? title : url }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        if isTitleOnly {
            return nil 
        }
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.iconProvider = NSItemProvider(object: UIImage.udLogo)
        metadata.originalURL = url
        metadata.url = url
        return metadata
    }
    
}
