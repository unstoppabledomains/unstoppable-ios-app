//
//  UIImage+SVG.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.07.2022.
//

import UIKit
import SVGKit

extension UIImage {
    static func from(svgData: Data) -> UIImage? {
        autoreleasepool {
            let svim = SVGKImage(data: svgData)
            let image = svim?.uiImage
            return image
        }
    }
}

