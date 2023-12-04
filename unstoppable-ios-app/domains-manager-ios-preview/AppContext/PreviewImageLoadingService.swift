//
//  PreviewImageLoadingService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

final class ImageLoadingService: ImageLoadingServiceProtocol {
    func loadImage(from source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage? {
        nil
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
