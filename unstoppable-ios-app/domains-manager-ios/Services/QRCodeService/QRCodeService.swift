//
//  QRCodeService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import UIKit

final class QRCodeService {
    private var serviceProvider: QRCodeServiceProvider = QRCodeMonkeyServiceProvider()
}

// MARK: - QRCodeServiceProtocol
extension QRCodeService: QRCodeServiceProtocol {
    func generateUDQRCode(for url: URL, with options: [Options]) async throws -> UIImage {
        let networkService = NetworkService()
        let requestURL = serviceProvider.serviceURL
        
        guard let body = serviceProvider.serviceRequestBody(for: url,
                                                            with: options) else {
            throw QRGenerateError.badRequest
        }
        
        let imageData = try await networkService.fetchData(for: requestURL,
                                                           body: body,
                                                           method: .post,
                                                           extraHeaders: [:])
        guard let image = UIImage(data: imageData) else {
            throw QRGenerateError.badResponse
        }
        return image
    }
}

extension QRCodeService {
    enum Options: Int {
        case withLogo
    }
}

extension QRCodeService {
    enum QRGenerateError: String, LocalizedError {
        case badRequest
        case badResponse
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
