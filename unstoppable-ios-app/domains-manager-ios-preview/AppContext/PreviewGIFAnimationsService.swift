//
//  PreviewGIFAnimationsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import UIKit

final class GIFAnimationsService {
    
    static let shared = GIFAnimationsService()
    
    func createGIFImageWithData(_ data: Data,
                                id: String,
                                maxImageSize: CGFloat,
                                maskingType: GIFMaskingType? = nil) async -> UIImage? {
        UIImage(data: data)
        
    }
    
    func prepareGIF(_ gif: GIF) async -> UIImage {
        .init()
    }
    
    func createImageForGIF(_ gif: GIF) async -> UIImage {
        .init()
    }
    
    func removeGIF(_ gif: GIF) {
        
    }
}
