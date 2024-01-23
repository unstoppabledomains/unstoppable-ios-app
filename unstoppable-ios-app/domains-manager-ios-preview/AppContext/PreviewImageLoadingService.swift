//
//  PreviewImageLoadingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

final class ImageLoadingService: ImageLoadingServiceProtocol {
    func loadImage(from source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage? {
        switch source {
        case .initials(let initials, let size, let style):
            return await InitialsView(initials: initials, size: size, style: style).toInitialsImage()
        default:
            return nil
        }
    }
    
    func cachedImage(for source: ImageSource) -> UIImage? {
        nil
    }
    
    func downsample(image: UIImage, downsampleDescription: DownsampleDescription) -> UIImage? {
        nil
    }
    
    func storeImage(_ image: UIImage, for source: ImageSource) async {
        
    }
    
    func getStoredImage(for source: ImageSource) async -> UIImage? {
        nil
    }
    
    func clearCache() async {
        
    }
    
    func clearStoredImages() async {
        
    }
    
    
}
