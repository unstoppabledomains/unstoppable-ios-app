//
//  PhotoLibraryImageSaver.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 30.01.2024.
//

import UIKit

final class PhotoLibraryImageSaver: NSObject {
    
    typealias SaveResult = Result<Void, Error>
    typealias SaveResultCallback = (SaveResult)->()
    
    private var saveResultCallback: SaveResultCallback?
   
    func saveImage(_ image: UIImage) async throws {
        try await withSafeCheckedThrowingMainActorContinuation { completion in
            saveImage(image) { result in
                switch result {
                case .success:
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveImage(_ image: UIImage,
                   saveResultCallback: SaveResultCallback? = nil) {
        Task { @MainActor in
            guard let topVC = appContext.coreAppCoordinator.topVC else { return }
            
            let granted = await appContext.permissionsService.askPermissionsFor(functionality: .photoLibrary(options: .addOnly),
                                                                                in: topVC,
                                                                                shouldShowAlertIfNotGranted: true)
            if granted {
                self.saveResultCallback = saveResultCallback
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.handleImageSavingWith(image:error:contextInfo:)), nil)
            } else {
                Vibration.error.vibrate()
                saveResultCallback?(.failure(SaveImageError.permissionsNotGranted))
            }
        }
    }
    
    @objc private func handleImageSavingWith(image: UIImage, error: Error?, contextInfo: UnsafeRawPointer) {
        Task { @MainActor in
            if let error {
                Vibration.error.vibrate()
                saveResultCallback?(.failure(error))
            } else {
                Vibration.success.vibrate()
                saveResultCallback?(.success(Void()))
            }
        }
    }
    
    enum SaveImageError: Error {
        case permissionsNotGranted
    }
}
