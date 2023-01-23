//
//  LoadPaginatedFetchableOperation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.08.2022.
//

import Foundation

final class LoadPaginatedFetchableOperation<T: PaginatedFetchable>: BaseOperation {
    
    typealias ResultBlock = (Result<[T], Error>)->()
    
    let batch: [T.O]
    let resultBlock: ResultBlock
    
    init(batch: [T.O], resultBlock: @escaping ResultBlock) {
        self.batch = batch
        self.resultBlock = resultBlock
    }
    
    override func start() {
        guard !checkIfCancelled() else {
            resultBlock(.failure(LoadError.cancelled))
            return
        }
        Task {
            do {
                let result: [T] = try await NetworkService().fetchAllPages(for: Array(batch))
                guard !checkIfCancelled() else {
                    resultBlock(.failure(LoadError.cancelled))
                    return
                }
                resultBlock(.success(result))
            } catch {
                resultBlock(.failure(error))
            }
            
            self.finish(true)
        }
    }
    
    enum LoadError: Error {
        case cancelled
    }
    
}
