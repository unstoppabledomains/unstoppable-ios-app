//
//  QRCodeMonkeyServiceProvider.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.05.2022.
//

import Foundation

final class QRCodeMonkeyServiceProvider {
    
    let serviceURL: URL = URL(string: "https://api.qrcode-monkey.com//qr/custom")!
    
}

extension QRCodeMonkeyServiceProvider: QRCodeServiceProvider {
    func serviceRequestBody(for url: URL, with options: [QRCodeService.Options]) -> String? {
        QRCodeMonkeyRequest(data: url, options: options).jsonString()
    }
}

// MARK: - Private methods
private extension QRCodeMonkeyServiceProvider {
    struct QRCodeMonkeyRequest: Codable {
  
        let data: URL
        var download: Bool
        var file: String
        var size: Float
        var config: Config
        
        internal init(data: URL,
                      options: [QRCodeService.Options]) {
            self.data = data
            self.download = false
            self.file = "png"
            self.size = 600
            self.config = .init()
            if options.contains(.withLogo) {
                config.logo = "8f5f5b0e8fcc72c2062a72839a394fcc2b8965e5.svg"
            }
        }
        
        struct Config: Codable {
            var body: String = "circle"
            var eye: String = "frame13"
            var eyeBall = "ball15"
            var bodyColor = "#000000"
            var bgColor = "#FFFFFF"
            var eye1Color = "#000000"
            var eye2Color = "#000000"
            var eye3Color = "#000000"
            var eyeBall1Color = "#000000"
            var eyeBall2Color = "#000000"
            var eyeBall3Color = "#000000"
            var gradientColor1 = ""
            var gradientColor2 = ""
            var gradientType = "linear"
            var gradientOnEyes = "true"
            var logo = ""
            var logoMode = "clean"
        }
    }
}
