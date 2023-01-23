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
        let svim = SVGKImage(data: svgData)
        return svim?.uiImage
    }
}

