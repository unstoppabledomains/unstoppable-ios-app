//
//  UIImage+GIF.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.02.2023.
//

import UIKit
import MobileCoreServices

extension UIImage {
    func gifDataRepresentation(gifDuration: TimeInterval = 0.0, loopCount: Int = 0) throws -> Data {
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
            if let cgimage = image.cgImage {
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
        let images = self.images ?? [self]
        let frameCount = images.count
        let frameDuration: TimeInterval = duration / Double(frameCount)
        let frameProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: NSNumber(value: frameDuration)
            ]
        ]
        
        var uiImages = [UIImage]()
        for image in images {
            if let cgimage = image.cgImage?.cropping(to: cropRect) {
                let uiImage = UIImage(cgImage: cgimage)
                uiImages.append(uiImage)
            }
        }
        
        
        
        return UIImage.animatedImage(with: uiImages,
                                     duration: Double(duration))
    }
}
