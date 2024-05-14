//
//  ImageLoadingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

final class ImageLoadingService {
        
    private let qrCodeService: QRCodeServiceProtocol
    private let loader: ImageDataLoader
    private let storage: ImagesStorageProtocol
    private let cacheStorage: ImagesCacheStorageProtocol
    private let serialQueue = DispatchQueue(label: "com.unstoppable.image.loading.serial")
    private var currentAsyncProcess = [String : Task<UIImage?, Never>]()
    
    init(qrCodeService: QRCodeServiceProtocol,
         loader: ImageDataLoader,
         storage: ImagesStorageProtocol,
         cacheStorage: ImagesCacheStorageProtocol) {
        self.qrCodeService = qrCodeService
        self.loader = loader
        self.storage = storage
        self.cacheStorage = cacheStorage
    }
    
}

// MARK: - ImageLoadingManagerProtocol
extension ImageLoadingService: ImageLoadingServiceProtocol {
    func loadImage(from source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage? {
        let downsampledCacheKey = source.keyFor(downsampleDescription: downsampleDescription)
        let imageKey = source.key
        if let cachedImage = cacheStorage.getCachedImage(for: downsampledCacheKey) {
            Debugger.printInfo(topic: .Images, "Will return cached image for key: \(imageKey)")
            return cachedImage
        }
        
        if let imageTask = serialQueue.sync(execute: { currentAsyncProcess[imageKey] }) {
            Debugger.printInfo(topic: .Images, "Will return active image loading task for key: \(imageKey)")
            return await imageTask.value
        }
        
        let task: Task<UIImage?, Never> = Task.detached(priority: .medium) {
            if let storedImage = await self.getStoredImage(for: imageKey) {
                Debugger.printInfo(topic: .Images, "Will return stored image for key: \(imageKey)")
                if let downsampleDescription,
                   let downsampledImage = self.downsampleAndCache(image: storedImage,
                                                                  downsampleDescription: downsampleDescription,
                                                                  cacheKey: downsampledCacheKey) {
                    return downsampledImage
                }
                return storedImage
            }
            
            if let image = await self.fetchImageFor(source: source, downsampleDescription: downsampleDescription) {
                Debugger.printInfo(topic: .Images, "Will return loaded image for key: \(imageKey)")
                return image
            } else {
                return nil
            }
        }
        
        serialQueue.sync { currentAsyncProcess[imageKey] = task }
        let image = await task.value
        serialQueue.sync { currentAsyncProcess[imageKey] = nil }
        
        return image
    }
    
    nonisolated
    func downsample(image: UIImage, downsampleDescription: DownsampleDescription) -> UIImage? {
        guard let imageData = image.pngData() ?? image.jpegData(compressionQuality: 1) else { return nil }

        return downsample(imageData: imageData, downsampleDescription: downsampleDescription)
    }
    
    func storeImage(_ image: UIImage, for source: ImageSource) async {
        guard let imageData = image.pngData() ?? image.jpegData(compressionQuality: 1) else { return }

        storage.storeImageData(imageData, for: source.key)
    }
    
    nonisolated
    func cachedImage(for source: ImageSource, downsampleDescription: DownsampleDescription?) -> UIImage? {
        cacheStorage.getCachedImage(for: source.keyFor(downsampleDescription: downsampleDescription))
    }
   
    func getStoredImage(for source: ImageSource) async -> UIImage? {
        await getStoredImage(for: source.key)
    }
  
    func clearCache() {
        cacheStorage.clearCache()
    }
    
    func clearStoredImages() async {
        storage.clearStoredImages()
    }
}

// MARK: - Private methods
fileprivate extension ImageLoadingService {
    func fetchImageFor(source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage? {
        switch source {
        case .url(let url, let maxImageSize):
            do {
                let imageData = try await loadImage(from: url)
                
                if let gif = await GIFAnimationsService.shared.createGIFImageWithData(imageData) {
                    scaleIfNeededAndSaveGif(gif, data: imageData, forKey: source.key)
                    
                    return gif
                }
                
                return autoreleasepool {
                    var finalImage: UIImage?
                  
                    if let image = UIImage(data: imageData) {
                        finalImage = image
                    } else {
                        finalImage = UIImage.from(svgData: imageData)
                    }
                    
                    if let maxImageSize {
                        finalImage = scaleIfNeeded(finalImage, maxImageSize: maxImageSize)
                    }
                    
                    if let downsampleDescription,
                       let image = finalImage,
                       let downsampledImage = self.downsample(image: image, downsampleDescription: downsampleDescription) {
                        finalImage = downsampledImage
                        cacheStorage.cache(image: downsampledImage, forKey: source.keyFor(downsampleDescription: downsampleDescription))
                    }
                    
                    guard let image = finalImage else { return nil }
                    
                    storeAndCache(image: image, forKey: source.key)
                    
                    return image
                }
            } catch {
                return nil
            }
        case .initials(let initials, let size, let style):
            if let cachedImage = self.cacheStorage.getCachedImage(for: source.key) {
                return cachedImage
            }
            if let image = await InitialsView(initials: initials, size: size, style: style).toInitialsImage() {
                self.cacheStorage.cache(image: image, forKey: source.key)
                return image
            }
            return nil
        case .domain(let domainItem):
            return await fetchImageFor(source: .domainPFPSource(domainItem.pfpSource),
                                       downsampleDescription: downsampleDescription)
        case .domainPFPSource(let pfpSource):
            switch pfpSource {
            case .nft(let imagePath), .nonNFT(let imagePath):
                guard let url = URL(string: imagePath) else { return nil }
                let start = Date()
                
                
                if let image = await fetchImageFor(source: .url(url, maxSize: Constants.downloadedImageMaxSize), downsampleDescription: downsampleDescription) {
                    Debugger.printTimeSensitiveInfo(topic: .Images,
                                                    "to load domain pfp",
                                                    startDate: start,
                                                    timeout: 3)
                    return image
                }
                return nil
            case .local(let image):
                return image
            case .none:
                return nil
            }
        case .domainNameInitials(let domainName, let size):
            return await fetchImageFor(source: .initials(domainName, size: size, style: .accent), downsampleDescription: downsampleDescription)
        case .domainInitials(let domainItem, let size):
            return await fetchImageFor(source: .domainNameInitials(domainItem.name, size: size), downsampleDescription: downsampleDescription)
        case .domainItemOrInitials(let domainItem, let size):
            if domainItem.pfpSource != .none,
               let image = await fetchImageFor(source: .domain(domainItem), downsampleDescription: downsampleDescription) {
                return image
            }
            return await fetchImageFor(source: .domainInitials(domainItem, size: size), downsampleDescription: downsampleDescription)
        case .currencyTicker(let ticker, let size, let style):
            if let image = UIImage(named: ticker) {
                cacheStorage.cache(image: image, forKey: source.keyFor(downsampleDescription: downsampleDescription))
                await storeImage(image, for: source)
                return image
            }
            if let url = URL(string: NetworkConfig.currencyIconUrl(for: ticker)),
               let image = await fetchImageFor(source: .url(url, maxSize: Constants.downloadedIconMaxSize), downsampleDescription: downsampleDescription) {
                cacheStorage.cache(image: image, forKey: source.keyFor(downsampleDescription: downsampleDescription))
                await storeImage(image, for: source)
                return image
            }
            return await fetchImageFor(source: .initials(ticker, size: size, style: style), downsampleDescription: downsampleDescription)
        case .currency(let currency, let size, let style):
            return await fetchImageFor(source: .currencyTicker(currency.ticker, size: size, style: style), downsampleDescription: downsampleDescription)
        case .wcApp(let appInfo, let size):
            if let url = appInfo.getIconURL(),
               let image = await fetchImageFor(source: .url(url, maxSize: Constants.downloadedIconMaxSize), downsampleDescription: downsampleDescription) {
                return image
            }
            return await fetchImageFor(source: .initials(appInfo.getDisplayName(), size: size, style: .gray), downsampleDescription: downsampleDescription)
        case .connectedApp(let appInfo, let size):
            let urlString = appInfo.appIconUrls
                .first(where: { URL(string: $0).pathExtensionPng }) ?? appInfo.appIconUrls.first
            if let urlString = urlString,
               let url = URL(string: urlString),
               let image = await fetchImageFor(source: .url(url, maxSize: Constants.downloadedIconMaxSize), downsampleDescription: downsampleDescription) {
                return image
            }
            return await fetchImageFor(source: .initials(appInfo.displayName, size: size, style: .gray), downsampleDescription: downsampleDescription)
        case .qrCode(let url, let options):
            if let image = try? await qrCodeService.generateUDQRCode(for: url,
                                                                     with: options),
               let scaledImage = scaleIfNeeded(image, maxImageSize: Constants.downloadedImageMaxSize) {
                storeAndCache(image: scaledImage, forKey: source.key)
                return scaledImage
            }
            return nil
        case .messagingUserPFPOrInitials(let userInfo, let size):
            if let url = userInfo.pfpURL,
               let image = await fetchImageFor(source: .url(url), downsampleDescription: downsampleDescription) {
                cacheStorage.cache(image: image, forKey: source.key)
                return image
            }
            let domainName = userInfo.anyDomainName
            return await fetchImageFor(source: .initials(domainName ?? userInfo.wallet.droppedHexPrefix,
                                                         size: size,
                                                         style: .accent),
                                       downsampleDescription: downsampleDescription)
        }
    }
    
    func scaleIfNeeded(_ image: UIImage?, maxImageSize: CGFloat) -> UIImage? {
        guard let image else { return nil }
        
        let scale = image.scale
        if ((image.size.width * scale) > maxImageSize || (image.size.height * scale) > maxImageSize),
           let imageData = image.pngData() {
            return downsample(imageData: imageData,
                              downsampleDescription: .init(size: CGSize(width: maxImageSize,
                                                                        height: maxImageSize),
                                                           scale: 1))
        } else {
            return image
        }
    }
    
    func scaleIfNeededAndSaveGif(_ image: UIImage, data: Data, forKey key: String) {
        if let adjustedData = try? image.gifDataRepresentation() {
            storeAndCache(imageData: adjustedData, image: image, forKey: key)
        } else {
            storeAndCache(imageData: data, image: image, forKey: key)
        }
    }
    
    func downsampleAndCache(image: UIImage, downsampleDescription: DownsampleDescription, cacheKey: String) -> UIImage? {
        guard let downsampledImage = image.gifImageDownsampled(to: downsampleDescription.size, scale: downsampleDescription.scale) else { return nil }
        self.cacheStorage.cache(image: downsampledImage, forKey: cacheKey)
        return downsampledImage
    }
    
    func loadImage(from url: URL) async throws -> Data {
        try await withSafeCheckedThrowingContinuation { completion in
            Task.detached {
                do {
                    let imageData = try await self.loader.loadImageDataFrom(url: url)
                    completion(.success(imageData))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getStoredImage(for key: String) async -> UIImage? {
        if let cachedImage = cacheStorage.getCachedImage(for: key) {
            return cachedImage
        }
        guard let imageData = storage.getStoredImage(for: key) else { return nil }
        
        var image: UIImage?
        if let gif = await GIFAnimationsService.shared.createGIFImageWithData(imageData) {
            image = gif
        } else if let justImage = UIImage(data: imageData) {
            image = justImage
        }
            
        guard let image else { return nil }
      
        cacheStorage.cache(image: image, forKey: key)
        return image
    }
    
    func storeAndCache(image: UIImage, forKey key: String) {
        if let imageData = image.pngData() {
            storeAndCache(imageData: imageData, image: image, forKey: key)
        } else if let imageData = image.jpegData(compressionQuality: 1) {
            storeAndCache(imageData: imageData, image: image, forKey: key)
        }
    }
    
    func storeAndCache(imageData: Data, image: UIImage, forKey key: String) {
        storage.storeImageData(imageData, for: key)
        cacheStorage.cache(image: image, forKey: key)
    }
    
    func downsample(imageAt imageURL: URL, to size: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else { return nil }
        
        return createThumbnail(from: imageSource, size: size, scale: scale)
    }
    
    nonisolated
    func downsample(imageData: Data, downsampleDescription: DownsampleDescription) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        return imageData.withUnsafeBytes { (unsafeRawBufferPointer: UnsafeRawBufferPointer) -> UIImage? in
            let unsafeBufferPointer = unsafeRawBufferPointer.bindMemory(to: UInt8.self)
            
            guard let unsafePointer = unsafeBufferPointer.baseAddress else { return nil }
            guard let data = CFDataCreate(kCFAllocatorDefault, unsafePointer, imageData.count) else { return nil }
            guard let imageSource = CGImageSourceCreateWithData(data, imageSourceOptions) else { return nil }
            
            return createThumbnail(from: imageSource, size: downsampleDescription.size, scale: downsampleDescription.scale)
        }
    }
    
    nonisolated
    private func createThumbnail(from imageSource: CGImageSource, size: CGSize, scale: CGFloat) -> UIImage? {
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
