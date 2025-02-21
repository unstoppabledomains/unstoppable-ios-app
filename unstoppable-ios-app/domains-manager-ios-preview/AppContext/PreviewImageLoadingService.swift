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
            await Task.sleep(seconds: 1)
            return UIImage.Preview.previewPortrait
        case .initials(let initials, let size, let style):
            return await InitialsView(initials: initials, size: size, style: style).toInitialsImage()
        case .domainNameInitials(let domainName, let size):
            return await loadImage(from: .initials(domainName, size: size, style: .accent),
                                   downsampleDescription: downsampleDescription)
        case .domainInitials(let domain, let size):
            return await loadImage(from: .domainNameInitials(domain.name, size: size),
                                   downsampleDescription: downsampleDescription)
        case .domainItemOrInitials(let domain, let size):
            if [true, false].randomElement() == true {
                return await loadImage(from: .domain(domain), downsampleDescription: downsampleDescription)
            }
            return await loadImage(from: .domainInitials(domain, size: size),
                                   downsampleDescription: downsampleDescription)
        case .currencyTicker(let ticker, let size, let style):
            return await loadImage(from: .initials(ticker, size: size, style: style), downsampleDescription: downsampleDescription)
        case .url(let url, let maxImageSize):
            do {
                return UIImage.Preview.previewLandscape
                let imageData = try Data(contentsOf: url)
                
                if let gif = await GIFAnimationsService.shared.createGIFImageWithData(imageData,
                                                                                      id: UUID().uuidString,
                                                                                      maxImageSize: maxImageSize ?? Constants.downloadedImageMaxSize) {
                    return gif
                }
                
                return autoreleasepool {
                    var finalImage: UIImage?
                    
                    if let image = UIImage(data: imageData) {
                        finalImage = image
                    } else {
                        finalImage = UIImage.from(svgData: imageData)
                    }
                    
                    if let downsampleDescription,
                       let image = finalImage,
                       let downsampledImage = self.downsample(image: image, downsampleDescription: downsampleDescription) {
                        finalImage = downsampledImage
                    }
                    
                    guard let image = finalImage else { return nil }
                    
                    return image
                }
            } catch {
                return nil
            }
        case .wcApp:
            return UIImage.Preview.previewSquare
        case .qrCode(_ , _):
            await Task.sleep(seconds: 1)
            return UIImage.Preview.previewSquare
        default:
            return nil
        }
    }
    
    func cachedImage(for source: ImageSource, downsampleDescription: DownsampleDescription?) -> UIImage? {
        nil
    }
    
    func downsample(image: UIImage, downsampleDescription: DownsampleDescription) -> UIImage? {
        image
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
