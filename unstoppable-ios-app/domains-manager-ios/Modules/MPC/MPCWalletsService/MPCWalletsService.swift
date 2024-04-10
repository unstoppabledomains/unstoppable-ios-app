//
//  MPCWalletsService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.04.2024.
//

import Foundation

final class MPCWalletsService {
    
    private var subServices = [MPCWalletProviderSubServiceProtocol]()
    
    private let udWalletsService: UDWalletsServiceProtocol
    
    init(udWalletsService: UDWalletsServiceProtocol) {
        self.udWalletsService = udWalletsService
        setup()
    }
    
}

// MARK: - Open methods
extension MPCWalletsService: MPCWalletsServiceProtocol {
    func sendBootstrapCodeTo(email: String) async throws {
        let subService = try getSubServiceFor(provider: .fireblocksUD)
        try await subService.sendBootstrapCodeTo(email: email)
    }
    
    func setupMPCWalletWith(code: String,
                            recoveryPhrase: String) -> AsyncThrowingStream<SetupMPCWalletStep, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let subService = try getSubServiceFor(provider: .fireblocksUD)
                    
                    for try await step in subService.setupMPCWalletWith(code: code, recoveryPhrase: recoveryPhrase) {
                        continuation.yield(step)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func signMessage(_ messageString: String,
                     by wallet: MPCWalletMetadata) async throws -> String {
        await Task.sleep(seconds: 0.5)
        let subService = try getSubServiceFor(provider: wallet.provider)
        
        throw MPCWalletsServiceError.unsupportedOperation
    }
}

// MARK: - Private methods
private extension MPCWalletsService {
    func getSubServiceFor(provider: MPCWalletProvider) throws -> MPCWalletProviderSubServiceProtocol {
        guard let subService = subServices.first(where: { $0.provider == provider }) else {
            Debugger.printFailure("Failed to get mpc wallet sub service for provider: \(provider.rawValue)")
            throw MPCWalletsServiceError.failedToGetSubService
        }
        
        return subService
    }
    
    enum MPCWalletsServiceError: String, LocalizedError {
        case failedToGetSubService
        case unsupportedOperation
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}

// MARK: - Setup methods
private extension MPCWalletsService {
    func setup() {
        setupSubServices()
    }
    
    func setupSubServices() {
        subServices = MPCWalletProvider.allCases.map { createSubServiceFor(provider: $0) }
    }
    
    func createSubServiceFor(provider: MPCWalletProvider) -> MPCWalletProviderSubServiceProtocol {
        switch provider {
        case .fireblocksUD:
            return FB_UD_MPC.MPCConnectionService(udWalletsService: udWalletsService)
        }
    }
}
