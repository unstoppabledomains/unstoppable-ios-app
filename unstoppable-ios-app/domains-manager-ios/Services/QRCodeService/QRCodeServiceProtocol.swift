//
//  QRCodeServiceProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import UIKit

protocol QRCodeServiceProtocol {
    func generateUDQRCode(for url: URL, with options: [QRCodeService.Options]) async throws -> UIImage
}
