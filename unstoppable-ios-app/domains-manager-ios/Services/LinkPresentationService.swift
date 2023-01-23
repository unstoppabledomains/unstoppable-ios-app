//
//  LinkPresentationService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.11.2022.
//

import Foundation
import LinkPresentation

protocol LinkPresentationServiceProtocol {
    func fetchLinkPresentationDescription(for url: URL) async -> LinkPresentationDescription
}

final class LinkPresentationService {
    
    private let cacheHolder = CacheHolder()
    private var currentAsyncProcess = [URL : Task<LinkPresentationDescription, Never>]()

}

// MARK: - LinkPresentationServiceProtocol
extension LinkPresentationService: LinkPresentationServiceProtocol {
    func fetchLinkPresentationDescription(for url: URL) async -> LinkPresentationDescription {
        if let metadata = await cacheHolder.metadata(for: url) {
            let image = await cacheHolder.image(for: url)
            return .init(title: metadata.title,
                         image: image)
        } else if let ongoingTask = currentAsyncProcess[url] {
            return await ongoingTask.value
        } else {
            let task: Task<LinkPresentationDescription, Never> = Task.detached(priority: .medium) {
                var title: String?
                var image: UIImage?
                if let metadata = await self.fetchLinkMetadata(for: url) {
                    await self.cacheHolder.set(metadata: metadata, for: url)
                    title = metadata.title
                    if let imageProvider = metadata.imageProvider,
                       imageProvider.canLoadObject(ofClass: UIImage.self),
                       let previewImage = await self.fetchImage(from: imageProvider) {
                        await self.cacheHolder.set(image: previewImage, for: url)
                        image = previewImage
                    }
                }
                return .init(title: title,
                             image: image)
            }
            currentAsyncProcess[url] = task
            let description = await task.value
            currentAsyncProcess[url] = nil
            
            return description
        }
    }
}

// MARK: - Private methods
private extension LinkPresentationService {
    func fetchImage(from imageProvider: NSItemProvider) async -> UIImage? {
        await withSafeCheckedContinuation({ completion in
            imageProvider.loadObject(ofClass: UIImage.self, completionHandler: { object, error in
                completion(object as? UIImage)
            })
        })
    }
    
    @MainActor
    func fetchLinkMetadata(for url: URL) async -> LPLinkMetadata? {
        let provider = LPMetadataProvider()
        return try? await provider.startFetchingMetadata(for: url)
    }
}

// MARK: - CacheHolder
private extension LinkPresentationService {
    actor CacheHolder {
        var metadataCache: [URL : LPLinkMetadata] = [:]
        var imagesCache: [URL : UIImage] = [:]
        
        func metadata(for url: URL) -> LPLinkMetadata? {
            metadataCache[url]
        }
        
        func image(for url: URL) -> UIImage? {
            imagesCache[url]
        }
        
        func set(metadata: LPLinkMetadata, for url: URL) {
            metadataCache[url] = metadata
        }
        
        func set(image: UIImage, for url: URL) {
            imagesCache[url] = image
        }
    }
}

struct LinkPresentationDescription {
    let title: String?
    let image: UIImage?
}
