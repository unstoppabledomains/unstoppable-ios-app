//
//  PreviewUIImage.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

extension UIImage {
//    func gifDataRepresentation(gifDuration: TimeInterval = 0.0, loopCount: Int = 0, quality: Double? = nil) throws -> Data {
//        pngData()!
//    }
//    func gifImageCropped(to cropRect: CGRect) -> UIImage? {
//     image
//    }
//    func gifImageDownsampled(to size: CGSize, scale: CGFloat) -> UIImage? {
//        self
//    }
}


final class GIFAnimationsService {
    
    static let shared = GIFAnimationsService()
    
    func createGIFImageWithData(_ data: Data,
                                maskingType: GIFMaskingType? = nil) async -> UIImage? {
        UIImage(data: data)
    
    }
}

extension GIFAnimationsService {
    enum GIFMaskingType {
        case maskWhite
        
        var maskingColorComponents: [CGFloat] {
            switch self {
            case .maskWhite:
                return [222, 255, 222, 255, 222, 255]
            }
        }
    }
}

extension UIImage {
    static func from(svgData: Data) -> UIImage? {
        UIImage(data: svgData)
    }
}
