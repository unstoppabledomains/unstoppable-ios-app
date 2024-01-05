//
//  ImageLoadingServiceTests.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 24.10.2023.
//

import XCTest
@testable import domains_manager_ios

final class ImageLoadingServiceTests: XCTestCase {
    
    private let mockImage = UIImage(named: "testImage", in: Bundle(for: ImageLoadingServiceTests.self), with: nil)!
    private var loader: MockImageDataLoader!
    private var storage: MockImagesStorage!
    private var cacheStorage: MockImagesCacheStorage!
    private var imageLoadingService: ImageLoadingService!
    
    override func setUp() async throws {
        loader = MockImageDataLoader(imageToDataBlock: convertImageToData(_:))
        storage = MockImagesStorage()
        cacheStorage = MockImagesCacheStorage()
        imageLoadingService = ImageLoadingService(qrCodeService: MockQRCodeService(),
                                                  loader: loader, storage: storage, cacheStorage: cacheStorage)
        imageLoadingService?.clearCache()
        await imageLoadingService?.clearStoredImages()
    }
    
    override func tearDown() async throws {
        loader.imageToReturn = nil
        await imageLoadingService?.clearStoredImages()
    }
    
    func testNormalLoading() async throws {
        loader.imageToReturn = mockImage
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let sourceKey = source.key
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        XCTAssertTrue(compareImages(image!, mockImage))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
    }
    
    func testLoadingSameSizeImage() async throws {
        loader.imageToReturn = mockImage
        let imageSize = mockImage.size
        let maxSize: CGFloat = max(imageSize.width, imageSize.height)
        let source: ImageSource = .url(getMockURL(), maxSize: maxSize)
        let sourceKey = source.key
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        XCTAssertTrue(compareImages(image!, mockImage))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
    }
    
    func testLoadingSmallImage() async throws {
        loader.imageToReturn = mockImage
        let imageSize = mockImage.size
        let maxSize: CGFloat = max(imageSize.width, imageSize.height)
        let source: ImageSource = .url(getMockURL(), maxSize: maxSize + 1)
        let sourceKey = source.key
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        XCTAssertTrue(compareImages(image!, mockImage))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
    }
    
    func testLoadingLargeImage() async throws {
        loader.imageToReturn = mockImage
        let imageSize = mockImage.size
        let minSize: CGFloat = max(imageSize.width, imageSize.height)
        let source: ImageSource = .url(getMockURL(), maxSize: minSize)
        let sourceKey = source.key
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        let downsampledImage = imageLoadingService.downsample(image: mockImage, downsampleDescription: .init(size: .init(width: minSize, height: minSize),
                                                                                                             scale: 1))
        XCTAssertTrue(compareImages(image!, downsampledImage!))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
    }
    
    func testLoadingImageMultipleTimeFromSameSource() async throws {
        loader.imageToReturn = mockImage
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        let image2 = await imageLoadingService.loadImage(from: source,
                                                         downsampleDescription: nil)
        let image3 = await imageLoadingService.loadImage(from: source,
                                                         downsampleDescription: nil)
        XCTAssertEqual(image, image2)
        XCTAssertEqual(image3, image2)
        XCTAssertEqual(1, loader.callsCounter)
    }
    
    func testLoadingSmallImageMultipleTimeFromSameSource() async throws {
        loader.imageToReturn = mockImage
        let imageSize = mockImage.size
        let minSize: CGFloat = max(imageSize.width, imageSize.height)
        let source: ImageSource = .url(getMockURL(), maxSize: minSize)
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        let image2 = await imageLoadingService.loadImage(from: source,
                                                         downsampleDescription: nil)
        let image3 = await imageLoadingService.loadImage(from: source,
                                                         downsampleDescription: nil)
        XCTAssertEqual(image, image2)
        XCTAssertEqual(image3, image2)
        XCTAssertEqual(1, loader.callsCounter)
    }
    
    func testLoadingDownsampledImageWithNoMaxSizeButDownsampleDescription() async throws {
        loader.imageToReturn = mockImage
        let imageSize = mockImage.size
        let minSize: CGFloat = max(imageSize.width, imageSize.height)
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let downsampleDescription = DownsampleDescription(size: .init(width: minSize,
                                                                      height: minSize),
                                                          scale: 1)
        let sourceKey = source.key
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: downsampleDescription)
        let downsampledImage = imageLoadingService.downsample(image: mockImage,
                                                              downsampleDescription: downsampleDescription)
        
        XCTAssertTrue(compareImages(image!, downsampledImage!))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertEqual(image!.size.maxSide, minSize)
    }
    
    func testLoadingDownsampledImageWithMaxSizeAndDownsampleDescription() async throws {
        loader.imageToReturn = mockImage
        let imageSize = mockImage.size
        let minSize: CGFloat = max(imageSize.width, imageSize.height)
        let source: ImageSource = .url(getMockURL(), maxSize: minSize)
        let downsampleDescription: DownsampleDescription = await .max
        let sourceKey = source.key
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: downsampleDescription)
        let downsampledImage = imageLoadingService.downsample(image: image!,
                                                              downsampleDescription: downsampleDescription)
        
        XCTAssertTrue(compareImages(image!, downsampledImage!))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertEqual(image, cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertEqual(image!.size.maxSide, downsampleDescription.size.maxSide)
    }
    
    func testLoadImagesFromDifferentSources() async throws {
        loader.imageToReturn = mockImage
        let source: ImageSource = .url(getMockURL(id: 0), maxSize: nil)
        let sourceKey = source.key
        let _ = await imageLoadingService.loadImage(from: source,
                                                    downsampleDescription: nil)
        
        let source2: ImageSource = .url(getMockURL(id: 1), maxSize: nil)
        let sourceKey2 = source2.key
        let _ = await imageLoadingService.loadImage(from: source2,
                                                    downsampleDescription: nil)
        
        
        
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey))
        XCTAssertNotNil(storage.getStoredImage(for: sourceKey2))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey2))
        XCTAssertEqual(2, storage.cache.count)
        XCTAssertEqual(2, cacheStorage.cache.count)
        XCTAssertEqual(2, loader.callsCounter)
    }
    
    func testImageAlreadyCached() async {
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        cacheStorage.cache(image: mockImage, forKey: source.key)
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        XCTAssertEqual(image, mockImage)
        XCTAssertEqual(0, loader.callsCounter)
    }
    
    func testImageAlreadyStored() async {
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let sourceKey = source.key
        let imageData = convertImageToData(mockImage)
        storage.storeImageData(imageData, for: sourceKey)
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: nil)
        XCTAssertTrue(compareImages(image!, mockImage))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertEqual(0, loader.callsCounter)
    }
    
    func testDownsampledImageAlreadyCached() async {
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let downsampleDescription: DownsampleDescription = .icon
        cacheStorage.cache(image: mockImage, forKey: source.keyFor(downsampleDescription: downsampleDescription))
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: downsampleDescription)
        XCTAssertEqual(image, mockImage)
        XCTAssertEqual(0, loader.callsCounter)
    }
    
    func testNotDownsampledImageAlreadyCached() async {
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let downsampleDescription: DownsampleDescription = .icon
        cacheStorage.cache(image: mockImage, forKey: source.key)
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: downsampleDescription)
        let downsampledImage = imageLoadingService.downsample(image: mockImage,
                                                              downsampleDescription: downsampleDescription)!
        XCTAssertTrue(compareImages(image!, downsampledImage))
        XCTAssertEqual(0, loader.callsCounter)
    }
    
    func testDownsampledImageAlreadyStored() async {
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let sourceKey = source.key
        let imageData = convertImageToData(mockImage)
        let downsampleDescription: DownsampleDescription = .icon
        storage.storeImageData(imageData, for: sourceKey)
        let image = await imageLoadingService.loadImage(from: source,
                                                        downsampleDescription: downsampleDescription)
        let downsampledImage = imageLoadingService.downsample(image: mockImage,
                                                              downsampleDescription: downsampleDescription)!
        XCTAssertTrue(compareImages(image!, downsampledImage))
        XCTAssertNotNil(cacheStorage.getCachedImage(for: sourceKey))
        XCTAssertEqual(0, loader.callsCounter)
    }
    
    func testStoredImageReusedToDownsample() async {
        let source: ImageSource = .url(getMockURL(), maxSize: nil)
        let sourceKey = source.key
        let imageData = convertImageToData(mockImage)
        storage.storeImageData(imageData, for: sourceKey)
        let _ = await imageLoadingService.loadImage(from: source,
                                                    downsampleDescription: .icon)
        let _ = await imageLoadingService.loadImage(from: source,
                                                    downsampleDescription: .init(maxSize: 5))
        
        XCTAssertEqual(storage.cache.count, 1)
        XCTAssertEqual(cacheStorage.cache.count, 3)
        XCTAssertEqual(0, loader.callsCounter)
    }
}

// MARK: - Private methods
private extension ImageLoadingServiceTests {
    func convertImageToData(_ image: UIImage) -> Data {
        image.pngData()!
    }
    
    func compareImages(_ image1: UIImage, _ image2: UIImage) -> Bool {
        let data1 = convertImageToData(image1)
        let data2 = convertImageToData(image2)
        return data1 == data2
    }
    
    func getMockURL(id: Int = 0) -> URL {
        URL(string: "https://ud.me/\(id)")!
    }
}

fileprivate final class MockImageDataLoader: ImageDataLoader {
    
    var imageToReturn: UIImage?
    var imageToDataBlock: (UIImage)->(Data)
    var callsCounter = 0
    
    init(imageToReturn: UIImage? = nil, imageToDataBlock: @escaping (UIImage) -> Data) {
        self.imageToReturn = imageToReturn
        self.imageToDataBlock = imageToDataBlock
    }
    
    func loadImageDataFrom(url: URL) async throws -> Data {
        callsCounter += 1
        if let imageToReturn {
            return imageToDataBlock(imageToReturn)
        }
        throw NSError()
    }
}

fileprivate final class MockImagesStorage: ImagesStorageProtocol {
    
    var cache: [String : Data] = [:]
    
    func getStoredImage(for key: String) -> Data? {
        cache[key]
    }
    
    func storeImageData(_ data: Data, for key: String) {
        cache[key] = data
    }
    
    func clearStoredImages() {
        cache.removeAll()
    }
    
}

fileprivate final class MockImagesCacheStorage: ImagesCacheStorageProtocol {
    var cache: [String : UIImage] = [:]
    
    func getCachedImage(for key: String) -> UIImage? {
        cache[key]
    }
    
    func cache(image: UIImage, forKey key: String) {
        cache[key] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

fileprivate final class MockQRCodeService: QRCodeServiceProtocol {
    func generateUDQRCode(for url: URL, with options: [domains_manager_ios.QRCodeService.Options]) async throws -> UIImage {
        throw NSError()
    }
}

fileprivate extension CGSize {
    var maxSide: CGFloat {
        max(width, height)
    }
}
