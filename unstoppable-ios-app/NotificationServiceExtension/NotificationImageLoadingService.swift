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
                    autoreleasepool {
                        if let imageData = data {
                            var finalImage: UIImage?
                            
                            if let image = self.downsample(imageData: imageData) {
                                finalImage = image
                            } else if let image = UIImage(data: imageData) {
                                finalImage = image
                            } else if let svgImage = UIImage.from(svgData: imageData) {
                                if let imageData = svgImage.jpegData(compressionQuality: 0.9),
                                   let downsampledImage = self.downsample(imageData: imageData) {
                                    finalImage = downsampledImage
                                } else {
                                    finalImage = svgImage
                                }
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
            let loader = DataLoader()
            loader.downloadFromURL(url, completion: completion)
        }
    }
    
    func storeAndCache(image: UIImage, forKey key: String) {
        autoreleasepool {
            if let imageData = image.jpegData(compressionQuality: 1) {
                storage.storeImageData(imageData, for: key)
            } else if let imageData = image.pngData() {
                storage.storeImageData(imageData, for: key)
            }
        }
    }
    
    func downsample(imageData: Data) -> UIImage? {
        autoreleasepool {
            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            return imageData.withUnsafeBytes { (unsafeRawBufferPointer: UnsafeRawBufferPointer) -> UIImage? in
                let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
                
                guard let unsafePointer = unsafeBufferPointer.baseAddress else { return nil }
                guard let data = CFDataCreate(kCFAllocatorDefault, unsafePointer, imageData.count) else { return nil }
                guard let imageSource = CGImageSourceCreateWithData(data, imageSourceOptions) else { return nil }
                
                return createThumbnail(from: imageSource,
                                       size: CGSize(width: 384, height: 384),
                                       scale: UIScreen.main.scale)
            }
        }
    }
    
    func createThumbnail(from imageSource: CGImageSource, size: CGSize, scale: CGFloat) -> UIImage? {
        autoreleasepool {
            let maxDimensionInPixels = max(size.width, size.height) * scale
            let options = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
            guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
            
            return UIImage(cgImage: thumbnail)
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

// MARK: - Private methods
private extension NotificationImageLoadingService {
    final class DataLoader: NSObject, URLSessionDownloadDelegate {
        
        typealias DataCallback = (Data?)->()
        
        private var urlSession: URLSession!
        private var completionCallback: DataCallback?
        
        override init() {
            super.init()
            urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
        
        func downloadFromURL(_ url: URL, completion: @escaping DataCallback) {
            self.completionCallback = completion
            let downloadTask = urlSession.downloadTask(with: url)
            downloadTask.resume()
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            let data = try? Data(contentsOf: location)
            finishWith(data: data)
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            if totalBytesExpectedToWrite > Constants.imageProfileMaxSize {
                // Drop download of very large images due to 24MB memory limit for NotificationExtension
                downloadTask.cancel()
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            finishWith(data: nil)
        }
        
        private func finishWith(data: Data?) {
            completionCallback?(data)
            completionCallback = nil
        }
    }
}
