//
//  UIImage+GIF.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.02.2023.
//

import UIKit
import MobileCoreServices

extension UIImage {
    func gifDataRepresentation(gifDuration: TimeInterval = 0.0, loopCount: Int = 0, quality: Double? = nil) throws -> Data {
        let images = self.images ?? [self]
        let frameCount = images.count
        let durationToUse = gifDuration <= 0.0 ? self.duration : gifDuration
        let frameDuration: TimeInterval = durationToUse / Double(frameCount)
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: NSNumber(value: frameDuration)
            ]
        ]
        
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeGIF, frameCount, nil) else {
            throw NSError(domain: "AnimatedGIFSerializationErrorDomain",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create destination with data."])
        }
        
        let imageProperties = [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: NSNumber(value: loopCount)]
        ] as CFDictionary
        CGImageDestinationSetProperties(destination, imageProperties)
        for image in images {
            if var cgimage = image.cgImage {
                if let quality {
                    let width = Int(Double(cgimage.width) * quality)
                    let height = Int(Double(cgimage.height) * quality)
                    if let resized = resizeCGImage(image: cgimage, width: width, height: height) {
                        cgimage = resized
                    }
                }
                CGImageDestinationAddImage(destination, cgimage, frameProperties as CFDictionary)
            }
        }
        
        let success = CGImageDestinationFinalize(destination)
        if !success {
            throw NSError(domain: "AnimatedGIFSerializationErrorDomain",
                          code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Could not finalize image destination"])
        }
        return mutableData as Data
    }
    
    func gifImageCropped(to cropRect: CGRect) -> UIImage? {
        transformGifImages { image in
            if let cgimage = image.cgImage?.cropping(to: cropRect) {
                return UIImage(cgImage: cgimage)
            }
            return nil
        }
    }
    
    func gifImageDownsampled(to size: CGSize, scale: CGFloat) -> UIImage? {
        transformGifImages { image in
            appContext.imageLoadingService.downsample(image: image,
                                                      downsampleDescription: .init(size: size,
                                                                                   scale: scale))
        }
    }
}

// MARK: - Private methods
private extension UIImage {
    func transformGifImages(_ transformBlock: (UIImage) ->(UIImage?)) -> UIImage? {
        let images = self.images ?? [self]
        let frameCount = images.count
        let frameDuration: TimeInterval = duration / Double(frameCount)
    
        var uiImages = [UIImage]()
        for image in images {
            if let transformedImage = transformBlock(image) {
                uiImages.append(transformedImage)
            }
        }
        
        return UIImage.animatedImage(with: uiImages,
                                     duration: Double(duration))
    }
    
    func resizeCGImage(image: CGImage, width: Int, height: Int) -> CGImage? {
        guard let colorSpace = image.colorSpace,
              let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: image.bitsPerComponent,
                                      bytesPerRow: image.bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: image.alphaInfo.rawValue) else { return nil }
        
        context.draw(image, in: CGRect(origin: .zero, size: .init(width: width, height: height)))
        
        return context.makeImage()
    }
}
