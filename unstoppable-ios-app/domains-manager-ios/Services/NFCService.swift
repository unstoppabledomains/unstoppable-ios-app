//
//  NFCService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.04.2023.
//

import UIKit
import CoreNFC

typealias NFCScanningResult = Result<[NFCNDEFMessage], NFCServiceError>
typealias NFCScanningResultCallback = (NFCScanningResult)->()

typealias NFCWritingResult = Result<Void, NFCServiceError>
typealias NFCWritingResultCallback = (NFCWritingResult)->()

final class NFCService: NSObject {
    
    static let shared = NFCService()
    private var session: NFCNDEFReaderSession?
    private var mode: Mode = .read
    private var scanningCallback: NFCScanningResultCallback?
    private var writingCallback: NFCWritingResultCallback?
    
    private override init() { }
    
}

// MARK: - Open methods
extension NFCService {
    var isNFCSupported: Bool { NFCNDEFReaderSession.readingAvailable && UIDevice.current.type.isNFCSupported }
    
    func beginScanning() async throws -> [NFCNDEFMessage] {
        return try await withCheckedThrowingContinuation { continuation in
            beginScanning() { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func writeURL(_ url: URL) async throws {
        guard let uriPayloadFromURL = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
            throw NFCServiceError.failedToCreatePayload
        }
        let message = NFCNDEFMessage(records: [uriPayloadFromURL])
        try await writeMessage(message)
    }

    func writeMessage(_ message: NFCNDEFMessage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            writeMessage(message) { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCService: NFCNDEFReaderSessionDelegate {
    func beginScanning(completionCallback: @escaping NFCScanningResultCallback) {
        guard session == nil else {
            completionCallback(.failure(.busy))
            return
        }
        guard NFCNDEFReaderSession.readingAvailable else {
            completionCallback(.failure(.readingNotAvailable))
            return
        }
        
        self.mode = .read
        self.scanningCallback = completionCallback
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near the item to learn more about it."
        session?.begin()
    }
    
    func writeMessage(_ message: NFCNDEFMessage, completionCallback: @escaping NFCWritingResultCallback) {
        guard session == nil else {
            completionCallback(.failure(.busy))
            return
        }
        
        self.mode = .write(message: message)
        self.writingCallback = completionCallback
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NDEF tag to write the message."
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        switch mode {
        case .read:
            finishScanningWith(messages: messages)
        case .write:
            return
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { [weak self] (error: Error?) in
            guard let self else { return }
            
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                self.finishWithError(.unableToConnectToTag)
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    self.finishWithError(.unableToQueryNDEFStatusOfTag)
                    return
                }
                
                
                func readTag() {
                    tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                        if nil != error || nil == message {
                            session.alertMessage = "Fail to read NDEF from tag"
                            self.finishWithError(.failedToReadNDEFFromTag)
                        } else {
                            session.alertMessage = "Found 1 NDEF message"
                            self.finishScanningWith(messages: [message!])
                        }
                    })
                }
                
                
                func writeMessage(_ message: NFCNDEFMessage) {
                    tag.writeNDEF(message, completionHandler: { (error: Error?) in
                        if nil != error {
                            session.alertMessage = "Write NDEF message fail: \(error!)"
                            self.finishWithError(.failedToReadNDEFFromTag)
                        } else {
                            session.alertMessage = "Write NDEF message successful."
                            self.finishWriting()
                        }
                    })
                }
                
                switch ndefStatus {
                case .notSupported:
                    session.alertMessage = "Tag is not NDEF compliant"
                    self.finishWithError(.tagIsNotNDEFCompliant)
                case .readOnly:
                    switch self.mode {
                    case .read:
                        readTag()
                    case .write:
                        session.alertMessage = "Tag is read only."
                        self.finishWithError(.tagIsReadOnly)
                    }
                case .readWrite:
                    switch self.mode {
                    case .read:
                        readTag()
                    case .write(let message):
                        writeMessage(message)
                    }
                @unknown default:
                    session.alertMessage = "Unknown NDEF tag status."
                    session.invalidate()
                }
            })
        })
    }
    
    /// - Tag: endScanning
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            // Show an alert when the invalidation reason is not because of a
            // successful read during a single-tag read session, or because the
            // user canceled a multiple-tag read session from the UI or
            // programmatically using the invalidate method call.
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                finishWithError(.readerError(readerError))
            }
        }
        
        // To read new tags, a new session instance is required.
        self.session = nil
    }
}

// MARK: - Private methods
private extension NFCService {
    func finishWithError(_ error: NFCServiceError) {
        switch mode {
        case .read:
            scanningCallback?(.failure(error))
        case .write:
            writingCallback?(.failure(error))
        }
        clean()
    }
    
    func finishScanningWith(messages: [NFCNDEFMessage]) {
        scanningCallback?(.success(messages))
        clean()
    }
    
    func finishWriting() {
        writingCallback?(.success(Void()))
        clean()
    }
    
    func clean() {
        session?.invalidate()
        session = nil
        scanningCallback = nil
        writingCallback = nil
    }
}

// MARK: - Mode
private extension NFCService {
    enum Mode {
        case read
        case write(message: NFCNDEFMessage)
    }
}

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
