//
//  ImagePicker.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.10.2022.
//

import UIKit
import Photos
import PhotosUI

typealias PhotoLibraryImagePickerCallback = (UIImage)->()

final class PhotoLibraryImagePicker: NSObject {
    
    static let shared = PhotoLibraryImagePicker()
    private var imagePickerCallback: PhotoLibraryImagePickerCallback?
    
    private override init() {
        super.init()
    }
    
    func pickImage(in viewController: UIViewController, imagePickerCallback: @escaping PhotoLibraryImagePickerCallback) {
        Task { @MainActor in
            let requiredFunctionality = PermissionsService.Functionality.photoLibrary(options: .addOnly)
            let isPermissionsGranted = await appContext.permissionsService.checkPermissionsFor(functionality: requiredFunctionality)
            
            if !isPermissionsGranted {
                guard await appContext.permissionsService.askPermissionsFor(functionality: requiredFunctionality,
                                                                            in: viewController,
                                                                            shouldShowAlertIfNotGranted: true) else { return }
            }
            
            self.imagePickerCallback = imagePickerCallback
            
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = 1
            let imagePicker = PHPickerViewController(configuration: config)
            imagePicker.delegate = self
            
            imagePicker.modalPresentationStyle = .fullScreen
            viewController.present(imagePicker, animated: true)
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PhotoLibraryImagePicker: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            picker.dismiss(animated: true) // User cancelled selection
            return
        }
        
        result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image", completionHandler: { [weak self] data, error in
            self?.didLoadImageData(data, error: error, from: picker)
        })
    }
}

// MARK: - Private methods
private extension PhotoLibraryImagePicker {
    func didLoadImageData(_ data: Data?, error: Error?, from picker: UIViewController) {
        Task {
            if let data {
                guard let image = await UIImage.createWith(anyData: data) else {
                    Debugger.printFailure("Failed to create image from any data", critical: false)
                    await didFailToPickImage(from: picker)
                    return
                }
                await didPick(image: image, from: picker)
            } else if let error {
                Debugger.printFailure("Failed to get image from PHImagePicker with error \(error.localizedDescription)", critical: false)
                await didFailToPickImage(from: picker)
            } else {
                Debugger.printFailure("Failed to get image from PHImagePicker without error and data 🤷‍♂️", critical: false)
                await didFailToPickImage(from: picker)
            }
        }
    }
    
    @MainActor
    func didPick(image: UIImage, from picker: UIViewController) {
        picker.presentingViewController?.dismiss(animated: true) { [weak self] in
            self?.imagePickerCallback?(image)
            self?.imagePickerCallback = nil
        }
    }
    
    @MainActor
    func didFailToPickImage(from picker: UIViewController) {
        self.imagePickerCallback = nil
        guard let presentingVC = picker.presentingViewController else {
            picker.dismiss(animated: true)
            Debugger.printFailure("Failed to get presenting view controller from image picker", critical: true)
            return
        }
        
        Task {
            await presentingVC.dismiss(animated: true)
            appContext.pullUpViewService.showSelectedImageBadPullUp(in: presentingVC)
        }
    }
}
