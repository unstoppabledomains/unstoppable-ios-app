//
//  QRScannerState.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.03.2024.
//

import Foundation

enum QRScannerState {
    case askingForPermissions
    case scanning
    case permissionsDenied
    case cameraNotAvailable
}
