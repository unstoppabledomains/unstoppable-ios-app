//
//  GIFAnimationsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.04.2022.
//

import UIKit

final class GIFAnimationsService {
       
    static let shared = GIFAnimationsService()
    
    private let stateHolder = StateHolder()

    private init() { }
    
}

// MARK: - Open methods
extension GIFAnimationsService {
    func prepareGIF(_ gif: GIF) async -> UIImage {
        if let gif = await stateHolder.cachedGifs[gif] {
            return gif
        }
        
        if let imageTask = await stateHolder.currentAsyncProcess[gif] {
            return await imageTask.value
        }
        
        let task: Task<UIImage, Never> = Task.detached(priority: .high) {
            guard let animation = await self.createGIFImageWithName(gif.name, maskingType: gif.maskingType) else {
                Debugger.printFailure("Failed to create GIF animation \(gif.name)", critical: true)
                return .init()
            }
            await self.stateHolder.cache(animation: animation, for: gif)
            return animation
        }
        
        await stateHolder.set(process: task, for: gif)
        let image = await task.value
        await stateHolder.set(process: nil, for: gif)
        
        return image
    }
    
    func createImageForGIF(_ gif: GIF) async -> UIImage {
        if let image = await stateHolder.cachedGifs[gif] {
            return image
        } else if let imageTask = await stateHolder.currentAsyncProcess[gif] {
            return await imageTask.value
        } else {
            return await prepareGIF(gif)
        }
    }
    
    func removeGIF(_ gif: GIF) {
        Task {
            await stateHolder.removeGIF(gif)
        }
    }
    
    func createGIFImageWithData(_ data: Data,
                                maskingType: GIFMaskingType? = nil) async -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            Debugger.printInfo("image doesn't exist")
            return nil
        }
        
        do {
            let image = try await animatedImageWithSource(source, maskingType: maskingType)
            return image
        } catch {
            Debugger.printFailure("Failed to create GIF image: \(error.localizedDescription)", critical: false)
            return nil
        }
    }
}

extension GIFAnimationsService {
    enum GIF: Int {
        case happyEnd
        
        fileprivate var name: String {
            switch self {
            case .happyEnd: return "allDoneConfettiAnimation"
            }
        }
        
        fileprivate var maskingType: GIFMaskingType? {
            switch self {
            case .happyEnd: return .maskWhite
            }
        }
    }
}

// MARK: - GIF animations. Use GIFAnimationsService to work with GIF animations
private extension GIFAnimationsService {
    func createGIFImageWithURL(_ gifUrl: String,
                               maskingType: GIFMaskingType?) async -> UIImage? {
        guard let bundleURL = URL(string: gifUrl) else {
            Debugger.printInfo("image named \"\(gifUrl)\" doesn't exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            Debugger.printInfo("image named \"\(gifUrl)\" into NSData")
            return nil
        }
        
        return await createGIFImageWithData(imageData, maskingType: maskingType)
    }
    
    func createGIFImageWithName(_ name: String,
                                maskingType: GIFMaskingType?) async -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
            Debugger.printInfo("This image named \"\(name)\" does not exist")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            Debugger.printInfo("Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return await createGIFImageWithData(imageData, maskingType: maskingType)
    }
    
    func animatedImageWithSource(_ source: CGImageSource,
                                 maskingType: GIFMaskingType?) async throws -> UIImage {
        let start = Date()
        let count = CGImageSourceGetCount(source)
        let (images, delays) = try await extractImagesWithDelays(from: source, maskingType: maskingType)
        Debugger.printWarning("\(String.itTook(from: start)) to prepare animation")
        
        let duration: Int = {
            var sum = 0
            
            for val: Int in delays {
                sum += val
            }
            
            return sum
        }()
        
        let gcd = try gcdForArray(delays)
        var frames = [UIImage]()
        
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        guard let animation = UIImage.animatedImage(with: frames,
                                                    duration: Double(duration) / 1000.0) else {
            throw GIFPreparationError.failedToCreateAnimatedImage
        }
        
        return animation
    }
    
    func extractImagesWithDelays(from source: CGImageSource,
                                 maskingType: GIFMaskingType?) async throws -> ImagesWithDelays {
        guard let cgContext = CGContext(data: nil, width: 10, height: 10, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0) else {
            throw GIFPreparationError.failedToCreateCGContext
        }
        let count = CGImageSourceGetCount(source)
        if count <= 1 {
            throw GIFPreparationError.oneOrLessFrames
        }
        guard let cgImage = cgContext.makeImage() else {
            throw GIFPreparationError.failedToMakeCGImage
        }
        var images = [CGImage](repeating: cgImage, count: count)
        var delays = [Int](repeating: 0, count: count)
        try await withThrowingTaskGroup(of: ImageToIndex.self, body: { group in
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ] as CFDictionary
            let sharedContext = CIContext(options: [.useSoftwareRenderer : false,
                                                    .highQualityDownsample: true])
            
            
            /// 1. Fill group with tasks
            for i in 0..<count {
                group.addTask {
                    guard let image = CGImageSourceCreateImageAtIndex(source, i, downsampleOptions),
                          let maskedImage = self.createCGImage(image, withMaskingType: maskingType),
                          let resizedImage = self.resizedImage(maskedImage,
                                                               scale: self.scaleForImage(image),
                                                               aspectRatio: 1,
                                                               in: sharedContext) else {
                        throw GIFPreparationError.failedToGetImageFromSource
                    }
                    
                    let delaySeconds = try self.delayForImageAtIndex(Int(i),
                                                                     source: source)
                    
                    /// Note: This block capturing self.
                    return ImageToIndex(image: resizedImage,
                                        delay: delaySeconds,
                                        i: i)
                }
            }
            
            /// 2. Take values from group
            for try await imageToIndex in group {
                let i = imageToIndex.i
                
                images.replaceSubrange(i...i, with: [imageToIndex.image])
                delays.replaceSubrange(i...i, with: [Int(imageToIndex.delay * 1000.0)]) // Seconds to ms
            }
        })
        
        return (images, delays)
    }
    
    func createCGImage(_ image: CGImage, withMaskingType maskingType: GIFMaskingType?) -> CGImage? {
        guard let maskingType else { return image }
        
        return image.copy(maskingColorComponents: maskingType.maskingColorComponents)
    }
    
    func scaleForImage(_ image: CGImage) -> CGFloat {
        let maxSize = max(image.height, image.width)
        let scale = min(1, Constants.downloadedImageMaxSize / CGFloat(maxSize))
        return scale
    }
    
    func resizedImage(_ cgImage: CGImage, scale: CGFloat, aspectRatio: CGFloat, in sharedContext: CIContext) -> CGImage? {
        autoreleasepool {
            let image = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CILanczosScaleTransform")
            filter?.setValue(image, forKey: kCIInputImageKey)
            filter?.setValue(scale, forKey: kCIInputScaleKey)
            filter?.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
            
            guard let outputCIImage = filter?.outputImage,
                  let outputCGImage = sharedContext.createCGImage(outputCIImage,
                                                                  from: outputCIImage.extent)
            else {
                return nil
            }
            
            return outputCGImage
        }
    }
    
    func delayForImageAtIndex(_ index: Int, source: CGImageSource) throws -> Double {
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        
        var value = CFDictionaryGetValue(cfProperties, unsafeBitCast(kCGImagePropertyGIFDictionary, to: UnsafeRawPointer.self))
        if value == nil {
            value = CFDictionaryGetValue(cfProperties, unsafeBitCast(kCGImagePropertyWebPDictionary, to: UnsafeRawPointer.self))
        }
        
        guard let value else { throw GIFPreparationError.failedToCastDelay }
        
        let gifProperties: CFDictionary = unsafeBitCast(value,
                                                        to: CFDictionary.self)
        
        
        var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                                        Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
                                                   to: AnyObject.self)
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                                                             Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        guard let delayDouble = delayObject as? Double else {
            throw GIFPreparationError.failedToCastDelay
        }
        
        return delayDouble
    }
    
    func gcdForPair(_ a: Int, _ b: Int) throws -> Int {
        var a = a
        var b = b
        
        
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            guard b != 0 else { throw GIFPreparationError.divisionByZero }
            
            rest = a % b
            
            if rest == 0 {
                return b
            } else {
                a = b
                b = rest
            }
        }
    }
    
    func gcdForArray(_ array: Array<Int>) throws -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = try gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    enum GIFPreparationError: String, LocalizedError {
        case divisionByZero
        case failedToCreateAnimatedImage
        case failedToCreateCGContext
        case failedToMakeCGImage
        case failedToGetImageFromSource
        case failedToCastDelay
        case oneOrLessFrames

        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - Entities
private extension GIFAnimationsService {
    struct ImageToIndex {
        let image: CGImage
        let delay: Double
        let i: Int
    }
    
    typealias ImagesWithDelays = ([CGImage], [Int])
}

// MARK: - StateHolder
private extension GIFAnimationsService {
    actor StateHolder {
        var cachedGifs: [GIF : UIImage] = [:]
        var currentAsyncProcess = [GIF : Task<UIImage, Never>]()
        
        func cache(animation: UIImage, for gif: GIF) {
            cachedGifs[gif] = animation
        }
        
        func set(process: Task<UIImage, Never>?, for gif: GIF) {
            if let process {
                currentAsyncProcess[gif] = process
            } else {
                currentAsyncProcess[gif] = nil
            }
        }
        
        func removeGIF(_ gif: GIF) {
            cachedGifs[gif] = nil
            currentAsyncProcess[gif]?.cancel()
            currentAsyncProcess[gif] = nil
        }
    }
}

extension GIFAnimationsService {
    enum GIFMaskingType {
        case maskWhite
        
        var maskingColorComponents: [CGFloat] {
            switch self {
            case .maskWhite:
                return [222, 255, 222, 255, 222, 255]
            }
        }
    }
}
