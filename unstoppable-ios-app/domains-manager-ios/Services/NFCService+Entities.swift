//
//  NFCService+Entities.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.12.2023.
//

import Foundation
import CoreNFC

typealias NFCScanningResult = Result<[NFCNDEFMessage], NFCServiceError>
typealias NFCScanningResultCallback = (NFCScanningResult)->()

typealias NFCWritingResult = Result<Void, NFCServiceError>
typealias NFCWritingResultCallback = (NFCWritingResult)->()

// MARK: - NFCServiceError
enum NFCServiceError: Error {
    case busy
    case failedToCreatePayload
    
    case readingNotAvailable
    case readerError(_ error: NFCReaderError)
    case unableToConnectToTag
    case tagIsNotNDEFCompliant
    case unableToQueryNDEFStatusOfTag
    case failedToReadNDEFFromTag
    case tagIsReadOnly
}
