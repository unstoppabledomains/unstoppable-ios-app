//
//  DomainProfileTopInfoData.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.10.2022.
//

import UIKit

struct DomainProfileTopInfoData {
    var avatarImageState: ImageState
    var bannerImageState: ImageState
    var imagePathPublic: Bool
    var coverPathPublic: Bool
    let social: DomainProfileSocialInfo
    let isUDBlue: Bool
    
    init(profile: SerializedUserDomainProfile) {
        imagePathPublic = profile.profile.imagePathPublic
        coverPathPublic = profile.profile.coverPathPublic
        isUDBlue = profile.profile.udBlue ?? false
        social = profile.social
        
        if let avatarPath = profile.profile.imagePath,
           let avatarURL = URL(string: avatarPath),
           let avatarType = profile.profile.imageType,
           avatarType != .default {
            avatarImageState = .untouched(source: .imageURL(avatarURL, imageType: avatarType))
        } else {
            avatarImageState = .untouched(source: nil)
        }
        if let coverPath = profile.profile.coverPath,
           let coverURL = URL(string: coverPath) {
            bannerImageState = .untouched(source: .imageURL(coverURL, imageType: .offChain))
        } else {
            bannerImageState = .untouched(source: nil)
        }
    }
    
    enum ImageState: Hashable {
        case untouched(source: ImageSource?), changed(image: UIImage), removed
        
        var isImageSet: Bool {
            switch self {
            case .untouched(let source):
                switch source {
                case .image, .imageURL:
                    return true
                case .none:
                    return false
                }
            case .changed:
                return true
            case .removed:
                return false
            }
        }
        
        var isOnChain: Bool {
            switch self {
            case .untouched(let source):
                switch source {
                case .image(_, let type), .imageURL(_, let type):
                    return type == .onChain
                case .none:
                    return false
                }
            case .changed:
                return false
            case .removed:
                return false
            }
        }
        
        var source: ImageSource? {
            switch self {
            case .untouched(let source):
                return source
            case .changed(let image):
                return .image(image, imageType: .offChain)
            case .removed:
                return nil 
            }
        }
        
        mutating func set(image: UIImage) {
            self = .changed(image: image)
        }
    }
    
    enum ImageSource: Hashable {
        case image(_ image: UIImage, imageType: DomainProfileImageType)
        case imageURL(_ url: URL, imageType: DomainProfileImageType)
    }
}
