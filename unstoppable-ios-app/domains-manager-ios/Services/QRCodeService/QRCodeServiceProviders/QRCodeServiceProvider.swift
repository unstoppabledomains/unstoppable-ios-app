//
//  QRCodeServiceProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import Foundation

protocol QRCodeServiceProvider {
    var serviceURL: URL { get }
    func serviceRequestBody(for url: URL, with options: [QRCodeService.Options]) -> String?
}
