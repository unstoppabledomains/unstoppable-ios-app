//
//  NotificationImageLoadingService.swift
//  NotificationServiceExtension
//
//  Created by Oleg Kuplin on 22.11.2022.
//

import UIKit

final class NotificationImageLoadingService {
    
    static let stagingHost = "staging.unstoppabledomains.com"
    static let productionHost = "unstoppabledomains.com"
    
    static let shared = NotificationImageLoadingService()
    
    private let storage = ImagesStorage()
    
    func imageFor(source: ImageSource, completion: @escaping ((UIImage?) -> ())) {
        switch source {
        case .url(let url):
            if let storedImageData = storage.getStoredImage(for: source.key),
               let image = UIImage(data: storedImageData) {
                completion(image)
            } else {
                loadImage(from: url) { data in
                    if let imageData = data {
                        var finalImage: UIImage?
                        
                        if let image = UIImage(data: imageData) {
                            finalImage = image
                        } else {
                            finalImage = UIImage.from(svgData: imageData)
                        }
                        if let finalImage {
                            self.storeAndCache(image: finalImage, forKey: source.key)
                        }
                        completion(finalImage)
                    } else {
                        completion(nil)
                    }
                }
            }
        case .domain(let domainName):
            if let avatarPath = AppGroupsBridgeService.shared.getAvatarPath(for: domainName),
               let avatarURL = URL(string: avatarPath) {
                imageFor(source: .url(avatarURL), completion: completion)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - Private methods
private extension NotificationImageLoadingService {
    func loadImage(from url: URL, completion: @escaping ((Data?)->())) {
        DispatchQueue.global().async {
            let imageData = try? Data(contentsOf: url)
            completion(imageData)
        }
    }
    
    func storeAndCache(image: UIImage, forKey key: String) {
        if let imageData = image.jpegData(compressionQuality: 1) {
            storage.storeImageData(imageData, for: key)
        } else if let imageData = image.pngData() {
            storage.storeImageData(imageData, for: key)
        }
    }
}

extension NotificationImageLoadingService {
    enum ImageSource {
        case url(_ url: URL)
        case domain(_ domainName: String)
        
        var key: String {
            switch self {
            case .url(let url):
                return url.absoluteString
            case .domain(let domainName):
                return domainName
            }
        }
    }
}
