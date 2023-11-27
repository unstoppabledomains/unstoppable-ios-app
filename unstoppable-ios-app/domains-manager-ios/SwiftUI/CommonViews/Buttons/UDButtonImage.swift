//
//  UDButtonIcon.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 20.11.2023.
//

import SwiftUI

enum UDButtonImage {
    case just(Image)
    case named(String)
    case system(String)
    case uiImage(UIImage)
    
    var image: Image {
        switch self {
        case .just(let image):
            return image
        case .named(let name):
            return Image(name)
        case .system(let systemName):
            return Image(systemName: systemName)
        case .uiImage(let uiImage):
            return Image(uiImage: uiImage)
        }
    }
    
    enum Alignment {
        case left, right
    }
}
