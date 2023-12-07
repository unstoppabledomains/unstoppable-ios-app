//
//  PreviewUIImage.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

extension UIImage {
    static func from(svgData: Data) -> UIImage? {
        UIImage(data: svgData)
    }
}
