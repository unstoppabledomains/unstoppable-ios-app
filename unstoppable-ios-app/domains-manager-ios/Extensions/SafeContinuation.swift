//
//  SafeContinuation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.10.2022.
//

import Foundation

@inlinable func withSafeCheckedContinuation<T>(function: String = #function,
                                    _ block: ( @Sendable  (@escaping (T)->())->()) ) async -> T {
    var didFireContinuation = false
    
    let res = await withCheckedContinuation({ (continuation: CheckedContinuation<T, Never>) in
        block { value in
            guard !didFireContinuation else {
                Debugger.printFailure("Continuation resume for more than once in function: \(function)", critical: true)
                return }
            
            didFireContinuation = true
            continuation.resume(returning: value)
        }
    })
    
    return res
}

@MainActor
@inlinable func withSafeCheckedMainActorContinuation<T>(critical: Bool = true,
                                                        function: String = #function,
                                                        _ block: ( @Sendable @MainActor  (@escaping (T)->())->()) ) async -> T {
    var didFireContinuation = false
    
    let res = await withCheckedContinuation({ (continuation: CheckedContinuation<T, Never>) in
        block { value in
            guard !didFireContinuation else {
                Debugger.printFailure("Continuation resume for more than once in function: \(function)", critical: critical)
                return }
            
            didFireContinuation = true
            continuation.resume(returning: value)
        }
    })
    
    return res
}

@inlinable func withSafeCheckedThrowingContinuation<T>(function: String = #function,
                                            _ block: ( @Sendable (@escaping (Result<T, any Error>)->())->()) ) async throws -> T {
    var didFireContinuation = false
    
    let res = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<T, Error>) in
        block { result in
            guard !didFireContinuation else {
                Debugger.printFailure("Second resume in \(function)", critical: true)
                return }
            
            didFireContinuation = true
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    })
    
    return res
}

@MainActor
@inlinable func withSafeCheckedThrowingMainActorContinuation<T>(critical: Bool = false,
                                                                function: String = #function,
                                                                _ block: ( @Sendable @MainActor (@escaping (Result<T, any Error>)->())->()) ) async throws -> T {
    var didFireContinuation = false
    
    let res = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<T, Error>) in
        block { result in
            guard !didFireContinuation else {
                Debugger.printFailure("Second resume in \(function)", critical: critical)
                return }
            
            didFireContinuation = true
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    })
    
    return res
}
