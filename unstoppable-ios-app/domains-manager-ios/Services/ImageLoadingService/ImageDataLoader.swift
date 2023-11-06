//
//  ImageDataLoader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.10.2023.
//

import Foundation

protocol ImageDataLoader {
    func loadImageDataFrom(url: URL) async throws -> Data
}

struct DefaultImageDataLoader: ImageDataLoader {
    func loadImageDataFrom(url: URL) async throws -> Data {
        let imageData = try Data(contentsOf: url)
        return imageData
    }
}
