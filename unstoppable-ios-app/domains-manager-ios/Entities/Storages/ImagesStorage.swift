//
//  ImagesStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.11.2022.
//

import Foundation

struct ImagesStorage {
    private let fileManager = FileManager.default
    private let storedImagesPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("StoredImages") as NSString
    
    init() {
        checkStoredImagesDirectory()
    }
}

// MARK: - Open methods
extension ImagesStorage {
    func getStoredImage(for key: String) -> Data? {
        let imagePath = pathForStoredImageAtKey(key)
        return try? Data.init(contentsOf: URL(fileURLWithPath: imagePath))
    }
    
    func storeImageData(_ data: Data, for key: String) {
        do {
            let imagePath = pathForStoredImageAtKey(key)
            try data.write(to: URL(fileURLWithPath: imagePath))
        } catch {
            Debugger.printInfo(topic: .Images, "Error: Couldn't save cached image to files")
        }
    }
    
    func clearStoredImages() {
        do {
            let paths = try fileManager.contentsOfDirectory(atPath: storedImagesPath as String)
            try paths.forEach { path in
                try fileManager.removeItem(atPath: storedImagesPath.appendingPathComponent(path))
            }
        } catch { }
    }
}

// MARK: - Private methods
private extension ImagesStorage {
    func pathForStoredImageAtKey(_ key: String) -> String {
        let encodedKey = Data(key.utf8).base64EncodedString().replacingOccurrences(of: "/", with: "").prefix(255)
        return pathForStoredImageWithName(String(encodedKey))
    }
    
    
    func pathForStoredImageWithName(_ name: String) -> String {
        storedImagesPath.appendingPathComponent(name)
    }
    
    func checkStoredImagesDirectory() {
        if !fileManager.fileExists(atPath: storedImagesPath as String) {
            do {
                try fileManager.createDirectory(atPath: storedImagesPath as String, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Debugger.printInfo(topic: .Images, "Error: Couldn't create directory for cached images")
            }
        }
    }
}
