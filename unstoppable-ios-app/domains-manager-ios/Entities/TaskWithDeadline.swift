//
//  TaskWithDeadline.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.02.2024.
//

import Foundation
import Combine

final class TaskWithDeadline<Value> {
        
    let deadline: TimeInterval
    let taskPublisher: Future<Value, Error>
    private var cancellables: [AnyCancellable] = []
    private var ongoingTask: Task<Value, Error>?
    private let responseQueue: DispatchQueue
    
    init(deadline: TimeInterval,
         responseQueue: DispatchQueue = .main,
         operation: @escaping @Sendable () async throws -> Value) {
        self.deadline = deadline
        self.responseQueue = responseQueue
        taskPublisher = Future<Value, Error> { promise in
            Task {
                do {
                    let value = try await operation()
                    responseQueue.async {
                        promise(.success(value))
                    }
                } catch {
                    responseQueue.async {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
    
    var value: Value {
        get async throws {
            if let ongoingTask {
                return try await ongoingTask.value
            }
            
            let ongoingTask = Task<Value, Error> {
                try await performOperationWithDelay()
            }
            self.ongoingTask = ongoingTask
            let result = try await ongoingTask.value
            self.ongoingTask = nil
            return result
        }
    }
    
    private func performOperationWithDelay() async throws -> Value {
        try await withSafeCheckedThrowingContinuation { continuation in
            taskPublisher
                .timeout(
                    .seconds(deadline),
                    scheduler: responseQueue,
                    options: nil,
                    customError: {
                        TaskError.timeout
                    })
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation(.failure(error))
                        }
                    },
                    receiveValue: { value in
                        continuation(.success(value))
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private enum TaskError: Error {
        case timeout
    }
}
