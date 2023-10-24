//
//  ImageLoadingService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.04.2022.
//

import UIKit

protocol ImageLoadingServiceProtocol {
    func loadImage(from source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage?
    func cachedImage(for source: ImageSource) -> UIImage?
    func downsample(image: UIImage, downsampleDescription: DownsampleDescription) -> UIImage?
    func storeImage(_ image: UIImage, for source: ImageSource) async
    func getStoredImage(for source: ImageSource) async -> UIImage?
    func clearCache() async
    func clearStoredImages() async
}
// MARK: - DownsampleDescription
struct DownsampleDescription {
    let size: CGSize
    let scale: CGFloat
    var cacheKey: String { "\(size.width)x\(size.height)x\(scale)" }
    
    init(size: CGSize, scale: CGFloat) {
        self.size = size
        self.scale = scale
    }
    
    init(maxSize: CGFloat, scale: CGFloat = 1) {
        self.init(size: .init(width: maxSize, height: maxSize), scale: scale)
    }
    
    static let max: DownsampleDescription = .init(maxSize: Constants.downloadedImageMaxSize)
    static let mid: DownsampleDescription = .init(maxSize: 256)
    static let icon: DownsampleDescription = .init(maxSize: Constants.downloadedIconMaxSize)
}

enum ImageSource {
    case url(_ url: URL, maxSize: CGFloat? = nil)
    case initials(_ name: String, size: InitialsView.InitialsSize, style: InitialsView.Style)
    case domain(_ domainItem: DomainDisplayInfo)
    case domainPFPSource(_ domainPFPSource: DomainPFPInfo.PFPSource)
    case domainInitials(_ domainItem: DomainDisplayInfo, size: InitialsView.InitialsSize)
    case domainItemOrInitials(_ domainItem: DomainDisplayInfo, size: InitialsView.InitialsSize)
    case currency(_ currency: CoinRecord, size: InitialsView.InitialsSize, style: InitialsView.Style)
    case wcApp(_ appInfo: WalletConnectService.WCServiceAppInfo, size: InitialsView.InitialsSize)
    case connectedApp(_ connectedApp: any UnifiedConnectAppInfoProtocol, size: InitialsView.InitialsSize)
    case qrCode(url: URL, options: [QRCodeService.Options])
    case messagingUserPFPOrInitials(_ userInfo: MessagingChatUserDisplayInfo, size: InitialsView.InitialsSize)

    var key: String {
        switch self {
        case .url(let url, _):
            return url.absoluteString
        case .initials(let name, let initialsSize, let style):
            var initials = Constants.defaultInitials
            if let firstChar = name.first {
                initials = firstChar.uppercased()
            }
            return initials + "_\(initialsSize.rawValue)_\(style.rawValue)"
        case .domain(let domainItem):
            return ImageSource.domainPFPSource(domainItem.pfpSource).key
        case .domainPFPSource(let pfpSource):
            return pfpSource.value
        case .domainInitials(let domainItem, let size):
            return ImageSource.initials(domainItem.name, size: size, style: .accent).key
        case .domainItemOrInitials(let domainItem, let size):
            if domainItem.pfpSource != .none {
                return ImageSource.domain(domainItem).key
            }
            return ImageSource.domainInitials(domainItem, size: size).key
        case .currency(let currency, let size, let style):
            return currency.ticker + "_\(size.rawValue)_\(style.rawValue)"
        case .wcApp(let appInfo, let size):
            return appInfo.getDisplayName() + "_\(size.rawValue)"
        case .connectedApp(let appInfo, let size):
            return appInfo.displayName + "_\(size.rawValue)"
        case .qrCode(let url, let options):
            let urlKey = ImageSource.url(url).key
            let optionsKey = options.sorted(by: { $0.rawValue < $1.rawValue }).map({ "\($0.rawValue)" }).joined(separator: "_")
            return urlKey + "_" + optionsKey
        case .messagingUserPFPOrInitials(let userInfo, _):
            return "messaging_" + userInfo.wallet.normalized
        }
    }
    
    func keyFor(downsampleDescription: DownsampleDescription?) -> String {
        if let downsampleDescription {
            return self.key + "_" + downsampleDescription.cacheKey
        }
        return self.key
    }
}

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
    // Currently downsample description is ignored. We set maximum size of upcoming image to 512px.
    func loadImage(from source: ImageSource, downsampleDescription: DownsampleDescription?) async -> UIImage? {
        let downsampledCacheKey = source.keyFor(downsampleDescription: downsampleDescription)
        let imageKey = source.key
        if let cachedImage = cacheStorage.cachedImage(for: downsampledCacheKey) {
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
    func cachedImage(for source: ImageSource) -> UIImage? {
        cacheStorage.cachedImage(for: source.key)
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
            if let cachedImage = self.cacheStorage.cachedImage(for: source.key) {
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
            case .none:
                return nil
            }
        case .domainInitials(let domainItem, let size):
            return await fetchImageFor(source: .initials(domainItem.name, size: size, style: .accent), downsampleDescription: downsampleDescription)
        case .domainItemOrInitials(let domainItem, let size):
            if domainItem.pfpSource != .none,
               let image = await fetchImageFor(source: .domain(domainItem), downsampleDescription: downsampleDescription) {
                return image
            }
            return await fetchImageFor(source: .domainInitials(domainItem, size: size), downsampleDescription: downsampleDescription)
        case .currency(let currency, let size, let style):
            if let url = URL(string: NetworkConfig.currencyIconUrl(for: currency)),
               let image = await fetchImageFor(source: .url(url, maxSize: Constants.downloadedIconMaxSize), downsampleDescription: downsampleDescription) {
                return image
            }
            return await fetchImageFor(source: .initials(currency.ticker, size: size, style: style), downsampleDescription: downsampleDescription)
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
            let domainName = (try? await NetworkService().fetchGlobalReverseResolution(for: userInfo.wallet.normalized))?.name
            if let domainName,
               !domainName.isEmpty,
               let urlString = await appContext.udDomainsService.loadPFP(for: domainName)?.pfpURL,
               let url = URL(string: urlString),
               let image = await fetchImageFor(source: .url(url), downsampleDescription: downsampleDescription) {
                cacheStorage.cache(image: image, forKey: source.key)
                return image
            }
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
        guard let downsampledImage = self.downsample(image: image, downsampleDescription: downsampleDescription) else { return nil }
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
        if let cachedImage = cacheStorage.cachedImage(for: key) {
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
