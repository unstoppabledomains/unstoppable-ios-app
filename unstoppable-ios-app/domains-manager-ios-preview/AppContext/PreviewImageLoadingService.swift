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
        case .domain:
            try? await Task.sleep(seconds: 1)
            return UIImage.Preview.previewPortrait
        case .initials(let initials, let size, let style):
            return await InitialsView(initials: initials, size: size, style: style).toInitialsImage()
        case .currencyTicker(let ticker, let size, let style):
            return await loadImage(from: .initials(ticker, size: size, style: style), downsampleDescription: downsampleDescription)
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
