//
//  NSLayoutHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.04.2022.
//

import UIKit

@IBDesignable class NSLayoutHelper : NSLayoutConstraint {
    @IBInspectable var iPhone4s: CGFloat = 0.0 {
        didSet { deviceConstant(.i3_5Inch,value:iPhone4s) }
    }
    @IBInspectable var iPhone5: CGFloat = 0.0 {
        didSet { deviceConstant(.i4Inch,value:iPhone5) }
    }
    @IBInspectable var iPhone8: CGFloat = 0.0 {
        didSet { deviceConstant(.i4_7Inch, value: iPhone8) }
    }
    @IBInspectable var iPhone8Plus: CGFloat = 0.0 {
        didSet { deviceConstant(.i5_5Inch,value:iPhone8Plus) }
    }
    @IBInspectable var iPhone11Pro: CGFloat = 0.0 {
        didSet { deviceConstant(.i5_8Inch,value:iPhone11Pro) }
    }
    @IBInspectable var iPhone11: CGFloat = 0.0 {
        didSet { deviceConstant(.i6_1Inch,value:iPhone11) }
    }
    @IBInspectable var iPhone11Max: CGFloat = 0.0 {
        didSet { deviceConstant(.i6_5Inch,value:iPhone11Max) }
    }
    @IBInspectable var iPhone12Mini: CGFloat = 0.0 {
        didSet { deviceConstant(.i5_4Inch,value:iPhone12Mini) }
    }
    @IBInspectable var iPhone12: CGFloat = 0.0 {
        didSet { deviceConstant(.i6_1Inch,value:iPhone12) }
    }
    @IBInspectable var iPhone12ProMax: CGFloat = 0.0 {
        didSet { deviceConstant(.i6_7Inch,value:iPhone12ProMax) }
    }
    @IBInspectable var iPadMini: CGFloat = 0.0 {
        didSet { deviceConstant(.i7_9Inch,value:iPadMini) }
    }
    @IBInspectable var iPadPro9_7: CGFloat = 0.0 {
        didSet { deviceConstant(.i9_7Inch,value:iPadPro9_7) }
    }
    @IBInspectable var iPadPro10_5: CGFloat = 0.0 {
        didSet { deviceConstant(.i10_5Inch,value:iPadPro10_5) }
    }
    @IBInspectable var iPadPro11: CGFloat = 0.0 {
        didSet { deviceConstant(.i11_Inch,value:iPadPro11) }
    }
    @IBInspectable var iPadPro12_9: CGFloat = 0.0 {
        didSet { deviceConstant(.i12_9Inch,value:iPadPro12_9) }
    }
    
    // Helpers
    open func deviceConstant(_ device: UIDeviceSize, value: CGFloat) {
        if deviceSize == device {
            constant = value
        }
    }
}
