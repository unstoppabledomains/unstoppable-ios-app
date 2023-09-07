//
//  ViewErrorHolder.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2023.
//

import Foundation

@MainActor
protocol ViewErrorHolder: AnyObject {
    var error: Error? { get set }
}

extension ViewErrorHolder {
    func performAsyncErrorCatchingBlock(_ block: (() async throws -> ()) ) async {
        do {
            try await block()
        } catch {
            self.error = error
        }
    }
}
