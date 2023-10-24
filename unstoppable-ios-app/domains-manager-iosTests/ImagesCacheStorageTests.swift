//
//  ImagesCacheStorageTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 24.10.2023.
//

import XCTest
@testable import domains_manager_ios

final class ImagesCacheStorageTests: XCTestCase {
    
    private var cacheStorage: ImagesCacheStorage!
    private let memoryLimit: Int = 1_000_000 // 1 MB
    
    override func setUp() async throws {
        cacheStorage = ImagesCacheStorage(maxCacheSize: memoryLimit)
    }
    
    override func tearDown() async throws {
        cacheStorage.clearCache()
    }
    
    func testViewCreatedWithExpectedMemoryFootprint() {
        let expectedMemory = 250_000
        let image = createImageWithMemorySize(expectedMemory)
        XCTAssertEqual(expectedMemory, image.memoryUsage)
    }
    
    func testLessThanLimitPersistInCache() {
        let numberOfImages = 4
        let memoryLimit = self.memoryLimit / numberOfImages
        for _ in 0..<numberOfImages {
            let image = createImageWithMemorySize(memoryLimit)
            cacheUniqueImage(image)
        }
        
        XCTAssertEqual(cacheStorage.numberOfCachedItems, numberOfImages)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, self.memoryLimit)
    }
    
    func testCachingForSameKeyOverride() {
        let key = UUID().uuidString
        let memory1 = 250_000
        let image1 = createImageWithMemorySize(memory1)
        cacheStorage.cache(image: image1, forKey: key)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory1)
        
        
        let memory2 = 360_000
        let image2 = createImageWithMemorySize(memory2)
        cacheStorage.cache(image: image2, forKey: key)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory2)
    }
    
    func testImageLargerThanCacheLimitAdded() {
        let key = UUID().uuidString
        let memory = 1_960_000
        let image = createImageWithMemorySize(memory)
        cacheStorage.cache(image: image, forKey: key)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
    }
    
    func testOlderSmallerImageReplacedInCache() {
        let memory1 = 360_000
        let image1 = createImageWithMemorySize(memory1)
        cacheUniqueImage(image1)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory1)
        
        let memory2 = 810_000
        let image2 = createImageWithMemorySize(memory2)
        cacheUniqueImage(image2)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory2)
    }
    
    func testOlderLargerImageReplacedInCache() {
        let memory1 = 810_000
        let image1 = createImageWithMemorySize(memory1)
        cacheUniqueImage(image1)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory1)
        
        
        let memory2 = 360_000
        let image2 = createImageWithMemorySize(memory2)
        cacheUniqueImage(image2)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory2)
    }
    
    func testOlderImageReplacedInCache() {
        let memory1 = 250_000
        let image1 = createImageWithMemorySize(memory1)
        cacheUniqueImage(image1)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory1)
        
        let memory2 = 360_000
        let image2 = createImageWithMemorySize(memory2)
        cacheUniqueImage(image2)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 2)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory2 + memory1)
        
        let memory3 = 518_400
        let image3 = createImageWithMemorySize(memory3)
        cacheUniqueImage(image3)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 2)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory2 + memory3)
    }
    
    func testOlderAddedButRecentlyUsedImageReplacedInCache() {
        let memory1 = 250_000
        let image1 = createImageWithMemorySize(memory1)
        let key1 = cacheUniqueImage(image1)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 1)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory1)
        
        let memory2 = 360_000
        let image2 = createImageWithMemorySize(memory2)
        cacheUniqueImage(image2)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 2)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory2 + memory1)
        
        _ = cacheStorage.cachedImage(for: key1) // Access older image
        
        let memory3 = 739_600
        let image3 = createImageWithMemorySize(memory3)
        cacheUniqueImage(image3)
        XCTAssertEqual(cacheStorage.numberOfCachedItems, 2)
        XCTAssertEqual(cacheStorage.cacheMemoryUsage, memory1 + memory3)
    }
}

// MARK: - Private methods
private extension ImagesCacheStorageTests {
    @discardableResult
    func cacheUniqueImage(_ image: UIImage) -> String {
        let key = UUID().uuidString
        cacheStorage.cache(image: image, forKey: key)
        return key
    }
    
    func createImageWithMemorySize(_ size: Int) -> UIImage {
        let scale: CGFloat = 1
        let widthAndHeightPixelsCount = CGFloat(size) / (CGFloat(UIImage.bitPerPixel) * scale)
        let sideSize = sqrt(widthAndHeightPixelsCount)
        
        let view = UIView(frame: CGRect(origin: .zero,
                                        size: .init(width: sideSize,
                                                    height: sideSize)))
        view.backgroundColor = .white
        
        let imageSize = view.bounds.size
        UIGraphicsBeginImageContextWithOptions(imageSize, true, scale)
        
        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = .high
        context.setAllowsFontSmoothing(true)
        context.setShouldSmoothFonts(true)
        
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}
